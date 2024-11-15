# pkg-sync

A tool for syncing packages in an on-prem builder instance with the packages in public builder.

Given a channel (defaults to `stable`) and an on-prem builder url and token, this tool can download all core, chef, or chef-platform packages in the channel from the piblic Chef Habitat builder that the on-prem instance does not already have and upload them to the on-prem builder.

This performs a pre-flight check to ensure that you do not have local core, chef, or chef-platform packages in the channel that are not in the same channel on bldr.habitat.sh. If there are, these local packages must be demoted.

This tool can also be used to generate a list of packages without actually syncing them.

## Usage

Install this package with:

```
hab pkg install habitat/pkg-sync --channel LTS-2024
```

Examples:

Sync all the latest core, chef, or chef-platform stable packages that you do not already have from the public builder and upload them to your on-prem builder instance.

```
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel stable --auth <your_public_Builder_instance_token>
```

Generate a list of all stable packages in the core, chef, and chef-platform origins.

```
hab pkg exec habitat/pkg-sync pkg-sync --generate-airgap-list --channel stable
```

These lists can be used with `hab pkg download` to download the hart files from builder:

```
hab pkg download --target x86_64-linux --channel stable --file package_list_x86_64-linux.txt --download-directory builder_bootstrap
hab pkg download --target x86_64-windows --channel stable --file package_list_x86_64-windows.txt --download-directory builder_bootstrap
```

You could then copy the `--download-directory` contents to an airgapped builder and use `hab pkg bulkupload` to upload them:

```
export HAB_AUTH_TOKEN=<your_on-prem_Builder_instance_token>
hab pkg bulkupload --url https://your-builder.tld --channel stable --auto-create-origins builder_bootstrap/
```