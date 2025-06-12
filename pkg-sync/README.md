# pkg-sync

A tool for syncing packages in an on-prem builder instance with the packages in public builder.

Given an origin (defaults to `core`), channel (defaults to `stable`) and an on-prem builder url and token, this tool can download all packages in the origin and channel from the public Chef Habitat builder that the on-prem instance does not already have and upload them to the on-prem builder.

This performs a pre-flight check to ensure that you do not have local packages in the channel that are not in the same channel on bldr.habitat.sh. If there are, these local packages must be demoted.

Optionally, one can specify a `--package-list` with a value of either `habitat` or `builder`. Rather than syncing all of the latest packages in the origin/channel, this will sync a predefined list of pckages. Specifying `habitat` will sync all packages included in a habitat release (cli, supervisor, studio, etc.). Specifying `builder` will sync all packages needed to run an on-prem builder instance. Note that when providing a `--package-list`, the above pre-flight check is not performed.

This tool can also be used to generate a list of packages without actually syncing them.

If for any reason, you end up in a state where packages were bulk uploaded and promoted to the wrong channel, one can use the `--idents-to-promote` option and provide a file with newline separated package identifiers that will be demoted from all non-unstable channels and promoted to the specified channel.

## Usage

Install this package with:

```
sudo hab pkg install habitat/pkg-sync --channel LTS-2024
```

Examples:

Sync all the latest core LTS-2024 packages that you do not already have from the public builder and upload them to your on-prem builder instance.

```
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --origin core --channel LTS-2024 --public-builder-token <your_public_Builder_instance_token> --private-builder-token <your_private_Builder_instance_token>
```

Sync all the latest stable habitat release packages from the public builder and upload them to your on-prem builder instance.

```
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel stable --package-list habitat --public-builder-token <your_public_Builder_instance_token> --private-builder-token <your_private_Builder_instance_token>
```

Generate a list of all stable packages in the core origin.

```
hab pkg exec habitat/pkg-sync pkg-sync --generate-airgap-list --origin core --channel stable --public-builder-token <your_public_Builder_instance_token>
```

These lists can be used with `hab pkg download` to download the hart files from builder:

```
hab pkg download -u https://bldr.habitat.sh -z <your_public_Builder_instance_token> --target x86_64-linux --channel stable --file package_list_x86_64-linux.txt --download-directory builder_bootstrap
hab pkg download -u https://bldr.habitat.sh -z <your_public_Builder_instance_token> --target x86_64-windows --channel stable --file package_list_x86_64-windows.txt --download-directory builder_bootstrap
```

You could then copy the `--download-directory` contents to an airgapped builder and use `hab pkg bulkupload` to upload them:

```
export HAB_AUTH_TOKEN=<your_on-prem_Builder_instance_token>
hab pkg bulkupload --url https://your-builder.tld --channel stable --auto-create-origins builder_bootstrap/
```

Promote packages that are in the LTS-2024 channel on the SAAS builder to that same channel on your local on-prem builder instance:

```
# Generate a list of all the latest LTS-2024 package identifiers
hab pkg exec habitat/pkg-sync pkg-sync --channel LTS-2024 --origin core --generate-airgap-list --public-builder-token <your_public_Builder_instance_token>
# Provide that list to --idents-to-promote so that any of those packages that exist on an on-prem instance are demoted from all non-unstable channels and promoted to LTS-2024
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel LTS-2024 --private-builder-token <your_private_Builder_instance_token> --idents-to-promote package_list_x86_64-linux.txt
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel LTS-2024 --private-builder-token <your_private_Builder_instance_token> --idents-to-promote package_list_x86_64-windows.txt
```

Note that the public builder tokens used in the examples below must be associated with a valid license key. See [these instructions](on-prem-docs/bootstrap-core.md#add-a-license-key) on entering a license key.