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
	Target string `json:"target"`
	Type   string `json:"package_type"`
}

var originList = []string{"core", "chef", "chef-platform"}

// parseArgs parses and validates command-line arguments
func parseArgs() (bldrURL, channel, auth string, generateListOnly, effortlessOnly, help bool) {
	flag.StringVar(&bldrURL, "bldr-url", "", "Base URL of your on-prem builder")
	flag.StringVar(&channel, "channel", "stable", "Refresh channel to sync")
	flag.StringVar(&auth, "auth", "", "Authorization Token for on-prem builder")
	flag.BoolVar(&generateListOnly, "generate-airgap-list", false, "Output list of package identifiers needed to download to a file in the current directory. If specified, --bldr-url is not required and a sync will not be performed.")
	// Uncomment once we have LTS-2024 releases for Chef infra and inspec
	// flag.BoolVar(&effortlessOnly, "effortless-only", false, "Only sync effortless packages")
	flag.BoolVar(&help, "help", false, "Show help message")
	flag.Parse()

	return
}

// fetchJSON makes an HTTP GET request to the specified URL and decodes the JSON response
func fetchJSON(url string, target interface{}) error {
	resp, err := http.Get(url)
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
func fetchPackages(bldrURL, channel string) ([]string, error) {
	rangeSize := 50
	var result []string
	for _, origin := range originList {
		fmt.Printf("\nFinding packages for origin %s in channel %s from %s\n", origin, channel, bldrURL)
		packageCount := 0
		for rangeIndex := 0; ; {
			fmt.Printf("\rFetching range %d-%d...", rangeIndex, rangeIndex+50)
			var response *PackageListResponse
			url := fmt.Sprintf("%s/v1/depot/channels/%s/%s/pkgs?range=%d", bldrURL, origin, channel, rangeIndex)
			err := fetchJSON(url, &response)
			if err != nil {
				return nil, fmt.Errorf("\nfailed to fetch package data from %s: %s", url, err.Error())
			} else {
				for _, pkg := range response.Data {
					result = append(result, fmt.Sprintf("%s/%s/%s/%s", pkg.Origin, pkg.Name, pkg.Version, pkg.Release))
				}
				packageCount += len(response.Data)
				rangeIndex += rangeSize
				if response.TotalCount == 0 || (response.RangeEnd+1) == response.TotalCount {
					break
				}
			}
		}
		fmt.Printf("\nDiscovered %d packages in origin %s\n", packageCount, origin)
	}
	slices.Sort(result)
	return result, nil
}

func fetchDetail(bldrURL, ident string) (*PackageDetails, error) {
	var response *PackageDetails
	url := fmt.Sprintf("%s/v1/depot/pkgs/%s", bldrURL, ident)
	err := fetchJSON(url, &response)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch package detail for %s: %s", ident, err.Error())
	} else {
		return response, nil
	}
}

func fetchLatestPackages(channel, target string, localPackages []string) ([]string, error) {
	var response *PackageListResponse
	var result []string
	for _, origin := range originList {
		fmt.Printf("\nFetching latest %s packages for origin %s in channel %s from public bldr...\n", target, origin, channel)
		url := fmt.Sprintf("https://bldr.habitat.sh/v1/depot/channels/%s/%s/pkgs/_latest?target=%s", origin, channel, target)
		err := fetchJSON(url, &response)
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
					detail, err := fetchDetail("https://bldr.habitat.sh", ident)
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

func sync(effortlessOnly bool, channel, bldrURL, auth string, localPackages []string, generateListOnly bool) error {
	for _, target := range []string{"x86_64-linux", "x86_64-windows"} {
		var latestPackages []string
		var err error

		// build a list of all packages that need to be downloaded
		if effortlessOnly {
			latestPackages = []string{"chef/chef-infra-client", "chef/inspec", "chef/scaffolding-chef-inspec", "chef/scaffolding-chef-infra"}
		} else {
			latestPackages, err = fetchLatestPackages(channel, target, localPackages)
			if err != nil {
				return err
			}
		}

		file, err := os.Create("package_list_" + target + ".txt")
		if err != nil {
			return err
		}

		if !generateListOnly {
			defer os.Remove(file.Name())
		}

		if len(latestPackages) == 0 {
			continue
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
			err = executeCommand("hab", "pkg", "download", "--download-directory", dir, "--target", target, "--channel", channel, "--file", file.Name())
			if err != nil {
				return err
			}

			fmt.Printf("\nUploading %s packages to %s", target, bldrURL)
			err = executeCommand("hab", "pkg", "bulkupload", "--url", bldrURL, "--channel", channel, "--auth", auth, "--auto-create-origins", dir)
			if err != nil {
				return err
			}
		} else {
			fmt.Printf("Generated list of packages needed to download at %s\n", file.Name())
		}
	}
	return nil
}

func preflightCheck(channel, bldrURL, auth string) ([]string, []string, error) {
	// Get complete list of all packages in channel on sass builder
	saasPackages, err := fetchPackages("https://bldr.habitat.sh", channel)
	if err != nil {
		return nil, nil, err
	}

	// Get complete list of all packages in channel on customer builder
	localPackages, err := fetchPackages(bldrURL, channel)
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

func main() {
	// Dont need errors prefixed with date and time
	log.SetFlags(0)

	bldrURL, channel, auth, generateListOnly, effortlessOnly, help := parseArgs()
	if help || (bldrURL == "" && !generateListOnly) {
		fmt.Printf("Usage: %s [OPTIONS]\n", os.Args[0])
		fmt.Println("Options:")
		flag.PrintDefaults()
		return
	}

	var localPackages, foreignPackages []string
	var err error
	if !generateListOnly {
		fmt.Printf("Starting preflight check for local %s packages not promoted to %s on bldr.habitat.sh...\n", channel, channel)
		localPackages, foreignPackages, err = preflightCheck(channel, bldrURL, auth)
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
					detail, err := fetchDetail(bldrURL, pkg)
					if err != nil {
						log.Fatalln(err.Error())
					}
					err = executeCommand("hab", "pkg", "demote", "-u", bldrURL, "-z", auth, pkg, channel, detail.Target)
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

	err = sync(effortlessOnly, channel, bldrURL, auth, localPackages, generateListOnly)
	if err != nil {
		log.Fatalln(err.Error())
	}

	fmt.Printf("Package sync with %s channel was succesful!\n", channel)
}
