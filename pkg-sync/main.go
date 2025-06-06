package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"slices"
	"strings"
)

type PackageList struct {
	Kind int
	List map[string][]string
}

const (
	PackageListNone int = iota
	PackageListBuilder
	PackageListHabitat
)

func (pl *PackageList) Set(s string) error {
	switch s {
	case "none":
		pl.Kind = PackageListNone
		return nil
	case "builder":
		pl.Kind = PackageListBuilder
		pl.List = map[string][]string{
			"x86_64-linux": []string{
				"core/hab",
				"core/hab-sup",
				"core/hab-launcher",
				"habitat/builder-minio",
				"habitat/builder-memcached",
				"habitat/builder-datastore",
				"habitat/builder-api",
				"habitat/builder-api-proxy",
			},
		}
		return nil
	case "habitat":
		pl.Kind = PackageListHabitat
		pl.List = map[string][]string{
			"x86_64-linux": []string{
				"core/hab-studio",
				"core/hab",
				"core/hab-sup",
				"core/hab-launcher",
				"core/hab-pkg-export-container",
				"core/hab-pkg-export-tar",
			},
			"x86_64-windows": []string{
				"core/hab-studio",
				"core/hab-plan-build-ps1",
				"core/windows-service",
				"core/hab",
				"core/hab-sup",
				"core/hab-launcher",
				"core/hab-pkg-export-container",
				"core/hab-pkg-export-tar",
			},
		}
		return nil
	}
	return fmt.Errorf("unknown package list specified: %s", s)
}

func (pl PackageList) String() string {
	switch pl.Kind {
	case PackageListNone:
		return "none"
	case PackageListBuilder:
		return "builder"
	case PackageListHabitat:
		return "habitat"
	}
	return "unknown"
}

type PackageListResponse struct {
	RangeEnd   int             `json:"range_end"`
	TotalCount int             `json:"total_count"`
	Data       []*PackageIdent `json:"data"`
}

type PackageIdent struct {
	Origin  string `json:"origin"`
	Name    string `json:"name"`
	Version string `json:"version"`
	Release string `json:"release"`
}

type PackageDetails struct {
	Target   string   `json:"target"`
	Type     string   `json:"package_type"`
	Channels []string `json:"channels"`
}

// parseArgs parses and validates command-line arguments
func parseArgs() (identsToPromote, origin, bldrURL, channel, privateToken, publicToken string, generateListOnly bool, packageList PackageList, help bool) {
	flag.StringVar(&identsToPromote, "idents-to-promote", "", "File with newline separated package identifiers that will be demoted from all non-unstable channels and promoted to the specified channel")
	flag.StringVar(&origin, "origin", "core", "Origin to sync")
	flag.StringVar(&bldrURL, "bldr-url", "", "Base URL of your on-prem builder")
	flag.StringVar(&channel, "channel", "stable", "Refresh channel to sync")
	flag.StringVar(&privateToken, "private-builder-token", "", "Authorization Token for on-prem builder")
	flag.StringVar(&publicToken, "public-builder-token", "", "Authorization Token for public builder at https://bldr.habitat.sh")
	flag.BoolVar(&generateListOnly, "generate-airgap-list", false, "Output list of package identifiers needed to download to a file in the current directory. If specified, --bldr-url is not required and a sync will not be performed.")
	flag.Var(&packageList, "package-list", "Only sync packages in list (none, builder, habitat)")
	flag.BoolVar(&help, "help", false, "Show help message")
	flag.Parse()

	return
}

// fetchJSON makes an HTTP GET request to the specified URL and decodes the JSON response
func fetchJSON(url, token string, target interface{}) error {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return json.NewDecoder(resp.Body).Decode(target)
	} else {
		return fmt.Errorf("Received status %d from %s", resp.StatusCode, url)
	}

}

// fetchPackages fetches packages for a given origin from the builder service
func fetchPackages(origin, bldrURL, channel, token string) ([]string, error) {
	rangeSize := 50
	var result []string
	fmt.Printf("\nFinding packages for origin %s in channel %s from %s\n", origin, channel, bldrURL)
	for rangeIndex := 0; ; {
		fmt.Printf("\rFetching range %d-%d...", rangeIndex, rangeIndex+rangeSize)
		var response *PackageListResponse
		url := fmt.Sprintf("%s/v1/depot/channels/%s/%s/pkgs?range=%d", bldrURL, origin, channel, rangeIndex)
		err := fetchJSON(url, token, &response)
		if err != nil {
			return nil, fmt.Errorf("\nfailed to fetch package data from %s: %s", url, err.Error())
		} else {
			for _, pkg := range response.Data {
				result = append(result, fmt.Sprintf("%s/%s/%s/%s", pkg.Origin, pkg.Name, pkg.Version, pkg.Release))
			}
			rangeIndex += rangeSize
			if response.TotalCount == 0 || (response.RangeEnd+1) == response.TotalCount {
				break
			}
		}
	}
	fmt.Printf("\nDiscovered %d packages in origin %s\n", len(result), origin)
	slices.Sort(result)
	return result, nil
}

func fetchDetail(bldrURL, ident, token string) (*PackageDetails, error) {
	var response *PackageDetails
	url := fmt.Sprintf("%s/v1/depot/pkgs/%s", bldrURL, ident)
	err := fetchJSON(url, token, &response)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch package detail for %s: %s", ident, err.Error())
	} else {
		return response, nil
	}
}

func fetchLatestPackages(origin, channel, target string, localPackages []string, publicToken string) ([]string, error) {
	var response *PackageListResponse
	var result []string
	fmt.Printf("\nFetching latest %s packages for origin %s in channel %s from public bldr...\n", target, origin, channel)
	url := fmt.Sprintf("https://bldr.habitat.sh/v1/depot/channels/%s/%s/pkgs/_latest?target=%s", origin, channel, target)
	err := fetchJSON(url, publicToken, &response)
	if err != nil {
		return nil, fmt.Errorf("Failed to fetch latest packages from %s: %s", url, err.Error())
	} else {
		fmt.Printf("Found %d latest %s packages for %s\n", len(response.Data), target, origin)
		pkgCount := 0
		for _, pkg := range response.Data {
			pkgCount = pkgCount + 1
			fmt.Printf("\rFetching detail for %d of %d packages", pkgCount, len(response.Data))
			ident := fmt.Sprintf("%s/%s/%s/%s", pkg.Origin, pkg.Name, pkg.Version, pkg.Release)
			if !slices.Contains(localPackages, ident) {
				detail, err := fetchDetail("https://bldr.habitat.sh", ident, publicToken)
				if err != nil {
					fmt.Println("")
					return nil, err
				}
				// filter out native and bootstrap packages used internally
				if !strings.Contains(pkg.Name, "-stage1") && !strings.Contains(pkg.Name, "-stage0") && !strings.HasPrefix(pkg.Name, "build-tools-") && detail.Type != "Native" {
					result = append(result, ident)
				}
			}
		}
	}
	fmt.Printf("\nFound %d latest %s packages needed to download\n", len(result), target)
	slices.Sort(result)
	return result, nil
}

func ReadYesNo() bool {
	r := bufio.NewReader(os.Stdin)
	var s string

	for {
		s, _ = r.ReadString('\n')
		s = strings.TrimSpace(s)
		s = strings.ToLower(s)
		if s == "y" {
			return true
		}
		if s == "n" {
			return false
		}
		fmt.Println("OOpsies! You did not enter a 'y' or an 'n'. Lets try again.")
	}
}

func executeCommand(command string, args ...string) error {
	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("Error calling %s: %s", strings.Join(append([]string{command}, args...), " "), err.Error())
	}
	return nil
}

func sync(packageList PackageList, origin, channel, bldrURL, privateToken, publicToken string, localPackages []string, generateListOnly bool) error {
	for _, target := range []string{"x86_64-linux", "x86_64-windows"} {
		var latestPackages []string
		var err error

		// build a list of all packages that need to be downloaded
		if packageList.Kind == PackageListNone {
			latestPackages, err = fetchLatestPackages(origin, channel, target, localPackages, publicToken)
			if err != nil {
				return err
			}
		} else {
			latestPackages = packageList.List[target]
		}

		if len(latestPackages) == 0 {
			continue
		}

		file, err := os.Create("package_list_" + target + ".txt")
		if err != nil {
			return err
		}

		if !generateListOnly {
			defer os.Remove(file.Name())
		}

		for _, pkg := range latestPackages {
			_, err = fmt.Fprintln(file, pkg)
			if err != nil {
				return err
			}
		}

		if !generateListOnly {
			dir, err := os.MkdirTemp("", "download_cache")
			if err != nil {
				return err
			}
			defer os.RemoveAll(dir)
			fmt.Printf("\nDownloading %s packages from http://bldr.habitat.sh to %s", target, dir)
			err = executeCommand("hab", "pkg", "download", "-u", "https://bldr.habitat.sh", "-z", publicToken, "--download-directory", dir, "--target", target, "--channel", channel, "--file", file.Name())
			if err != nil {
				return err
			}

			fmt.Printf("\nUploading %s packages to %s", target, bldrURL)
			err = executeCommand("hab", "pkg", "bulkupload", "--url", bldrURL, "--channel", channel, "--auth", privateToken, "--auto-create-origins", dir)
			if err != nil {
				return err
			}
		} else {
			fmt.Printf("Generated list of packages needed to download at %s\n", file.Name())
		}
	}
	return nil
}

func preflightCheck(origin, channel, bldrURL, privateToken, publicToken string) ([]string, []string, error) {
	// Get complete list of all packages in channel on sass builder
	saasPackages, err := fetchPackages(origin, "https://bldr.habitat.sh", channel, publicToken)
	if err != nil {
		return nil, nil, err
	}

	// Get complete list of all packages in channel on customer builder
	localPackages, err := fetchPackages(origin, bldrURL, channel, privateToken)
	if err != nil {
		return nil, nil, err
	}

	// Look for cases where the customer has promoted a package on their own builder
	// that has not been promoted by chef
	var foreignPackages []string
	for _, pkg := range localPackages {
		if !slices.Contains(saasPackages, pkg) {
			foreignPackages = append(foreignPackages, pkg)
		}
	}

	return localPackages, foreignPackages, nil
}

func moveToChannel(identsToPromote, channel, bldrURL, privateToken string) error {
	file, err := os.Open(identsToPromote)
	if err != nil {
		return fmt.Errorf("\nfailed to open file %s: %s", identsToPromote, err.Error())
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		pkg := scanner.Text()
		detail, err := fetchDetail(bldrURL, pkg, privateToken)
		if err != nil {
			continue
		}
		for _, ch := range detail.Channels {
			if ch == "unstable" || ch == "channel" {
				continue
			}
			err = executeCommand("hab", "pkg", "demote", "-u", bldrURL, "-z", privateToken, pkg, ch, detail.Target)
			if err != nil {
				return err
			}
		}
		err = executeCommand("hab", "pkg", "promote", "-u", bldrURL, "-z", privateToken, pkg, channel, detail.Target)
		if err != nil {
			return err
		}
	}

	if err := scanner.Err(); err != nil {
		return fmt.Errorf("\nerror reading file %s: %s", identsToPromote, err.Error())
	}
	return nil
}

func main() {
	// Dont need errors prefixed with date and time
	log.SetFlags(0)

	identsToPromote, origin, bldrURL, channel, privateToken, publicToken, generateListOnly, packageList, help := parseArgs()
	if help || (bldrURL == "" && !generateListOnly) {
		fmt.Printf("Usage: %s [OPTIONS]\n", os.Args[0])
		fmt.Println("Options:")
		flag.PrintDefaults()
		return
	}

	var err error
	if len(identsToPromote) > 0 {
		err = moveToChannel(identsToPromote, channel, bldrURL, privateToken)
		if err != nil {
			log.Fatalln(err.Error())
		}
		return
	}
	var localPackages, foreignPackages []string

	if !generateListOnly && packageList.Kind == PackageListNone {
		fmt.Printf("Starting preflight check for local %s packages not promoted to %s on bldr.habitat.sh...\n", channel, channel)
		localPackages, foreignPackages, err = preflightCheck(origin, channel, bldrURL, privateToken, publicToken)
		if err != nil {
			log.Fatalln(err.Error())
		}
		// To prevent the possibility of build issues, we now need to demote these packages
		if foreignPackages != nil {
			fmt.Printf("\nFound the following local packages in the %s channel that are not on bldr.habitat.sh:\n", channel)
			for _, pkg := range foreignPackages {
				fmt.Println(pkg)
			}
			fmt.Printf("These packages must be demoted from %s before we can continue. Shall we demote them?(y/n)\n", channel)

			if !ReadYesNo() {
				fmt.Println("Exiting sync")
				return
			} else {
				for _, pkg := range foreignPackages {
					fmt.Println("Demoting", pkg)
					detail, err := fetchDetail(bldrURL, pkg, privateToken)
					if err != nil {
						log.Fatalln(err.Error())
					}
					err = executeCommand("hab", "pkg", "demote", "-u", bldrURL, "-z", privateToken, pkg, channel, detail.Target)
					if err != nil {
						log.Fatalln(err.Error())
					}
				}
				fmt.Println("Succesfully demoted all conflicting packages.")
			}
		} else {
			fmt.Println("No conflicting packages found.")
		}
	}

	err = sync(packageList, origin, channel, bldrURL, privateToken, publicToken, localPackages, generateListOnly)
	if err != nil {
		log.Fatalln(err.Error())
	}

	fmt.Printf("Package sync with %s channel was succesful!\n", channel)
}
