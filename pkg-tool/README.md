# pkg-tool

A tool for discovering all packages in an origin and their dependencies

This tool can point to any accesible on-prem builder URL and collect a list of all packages in one or more origins. The tool will traverse all dependencies (direct and transitive) of those packages and include them in a final list that can be shared with the Progress team.

## Usage

Install this package with:

```
hab pkg install habitat/pkg-tool
```

The tool can be run with:

```
hab pkg exec habitat/pkg-tool pkg-tool --origins <ORIGIN LIST> --bldr-url <BLDR URL>
``

`ORIGIN LIST` is either a single origin name or a comma separated list of origins.
`BLDR_RRL` is the URL for your on-prem habitat builder (depot).

example:
hab pkg exec habitat/pkg-tool pkg-tool --origins mwrock3,habitat --bldr-url https://bldr.habitat.sh

This will find all packages in both the `mwrock3` and `habitat` origins on `https://bldr.habitat.sh` and list them along with all of their dependent packages in a file named `packages.txt`.
