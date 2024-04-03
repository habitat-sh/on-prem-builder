package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"os"
	"sort"
	"strings"
	"sync"
)

type PackageListResponse struct {
	Data []*Package `json:"data"`
}

// Package represents a basic package structure
type Package struct {
	Origin string `json:"origin"`
	Name   string `json:"name"`
}

// Dependency represents a dependency structure
type Dependency struct {
	Origin  string `json:"origin"`
	Name    string `json:"name"`
	Version string `json:"version"`
	Release string `json:"release"`
}

// parseArgs parses and validates command-line arguments
func parseArgs() (bldrURL, origins, output string, help bool) {
	flag.StringVar(&bldrURL, "bldr-url", "", "Base URL of the builder")
	flag.StringVar(&origins, "origins", "", "Comma-separated list of origins")
	flag.StringVar(&output, "output", "packages.txt", "Output file for the packages")
	flag.BoolVar(&help, "help", false, "Show help message")
	flag.Parse()

	return
}

// fetchJSON makes an HTTP GET request to the specified URL and decodes the JSON response
func fetchJSON(url string, target interface{}) (bool, error) {
	resp, err := http.Get(url)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return true, json.NewDecoder(resp.Body).Decode(target)
	} else {
		return false, nil
	}

}

// fetchPackages fetches packages for a given origin from the builder service
func fetchPackages(bldrURL, origin string, packagesChan chan<- *Package) {
	rangeSize := 50
	packageCount := 0
	for rangeIndex := 0; ; {
		fmt.Printf("fetching packages for origin %s range %d-%d\n", origin, rangeIndex, rangeIndex+50)
		var response *PackageListResponse
		url := fmt.Sprintf("%s/v1/depot/%s/pkgs?range=%d", bldrURL, origin, rangeIndex)
		ok, err := fetchJSON(url, &response)
		if err != nil {
			fmt.Printf("failed to fetch package data: %s\n", err.Error())
			break
		}
		if ok {
			if len(response.Data) == 0 {
				break
			}
			for _, pkg := range response.Data {
				packagesChan <- pkg
			}
			packageCount += len(response.Data)
			rangeIndex += rangeSize
		}
	}
	fmt.Printf("discovered %d packages in origin %s\n", packageCount, origin)
}

// fetchDependencies fetches dependencies for a given package and target
func fetchDependencies(bldrURL string, pkg *Package, target string, depsChan chan<- string) {
	fmt.Printf("fetching deps for %s/%s (%s)\n", pkg.Origin, pkg.Name, target)
	url := fmt.Sprintf("%s/v1/depot/pkgs/%s/%s/latest?target=%s", bldrURL, pkg.Origin, pkg.Name, target)
	var response struct {
		Tdeps      []Dependency `json:"tdeps"`
		BuildTdeps []Dependency `json:"build_tdeps"`
	}
	ok, err := fetchJSON(url, &response)
	if err != nil {
		fmt.Printf("failed to fetch dependencies for package %s/%s (%s): %s\n", pkg.Origin, pkg.Name, target, err.Error())
		return // Handle error or log as needed
	}
	if ok {
		for _, dep := range append(response.Tdeps, response.BuildTdeps...) {
			depString := fmt.Sprintf("%s/%s/%s/%s", dep.Origin, dep.Name, dep.Version, dep.Release)
			depsChan <- depString
		}
	}
}

func main() {
	bldrURL, origins, output, help := parseArgs()
	if help || bldrURL == "" || origins == "" {
		fmt.Println("usage: pkg-tool --origins <ORIGINS> --bldr-url <BLDR_URL>")
		fmt.Println("example: pkg-tool --origins chef,habitat --bldr-url https://bldr.habitat.sh")
		flag.PrintDefaults()
		return
	}

	originList := strings.Split(origins, ",")
	packagesChan := make(chan *Package, 100)
	depsChan := make(chan string, 1000)
	var wg sync.WaitGroup

	// Fetch packages
	for _, origin := range originList {
		wg.Add(1)
		go func(origin string) {
			defer wg.Done()
			fetchPackages(bldrURL, origin, packagesChan)
		}(origin)
	}

	go func() {
		wg.Wait()
		close(packagesChan)
	}()

	// Process packages to fetch dependencies
	go func() {
		targets := []string{"x86_64-linux", "x86_64-linux-2", "x86_64-windows"}
		for pkg := range packagesChan {
			for _, target := range targets {
				wg.Add(1)
				go func(pkg *Package, target string) {
					defer wg.Done()
					fetchDependencies(bldrURL, pkg, target, depsChan)
				}(pkg, target)
			}
		}
		wg.Wait()
		close(depsChan)
	}()

	// Collect and write dependencies
	depsSet := make(map[string]struct{})
	for dep := range depsChan {
		depsSet[dep] = struct{}{}
	}

	var depsList []string
	for dep := range depsSet {
		depsList = append(depsList, dep)
	}
	sort.Sort(sort.StringSlice(depsList))
	err := os.WriteFile(output, []byte(strings.Join(depsList, "\n")), 0644)
	if err != nil {
		panic(err)
	}
	fmt.Printf("Packages written to \"%s\"\n", output)
	fmt.Println("Please share this file with the Progress Customer Success team.")
}
