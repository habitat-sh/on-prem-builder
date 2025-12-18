# pkg-sync

A tool for syncing packages in an on-prem builder instance with the packages in public builder.

## What is Package Syncing?

Package syncing allows you to keep your on-premises Habitat Builder instance up-to-date with packages from the public/SaaS Chef Habitat Builder. This is essential for:
- Maintaining access to the latest core packages and dependencies
- Ensuring your on-prem builder has all necessary packages for building and running applications
- Synchronizing specific package sets like Habitat CLI tools or Builder components

For **Habitat 2.0**, the default channel has changed from `stable` to `base` to provide better lifecycle management and compatibility.

Given an origin (defaults to `core`), channel (defaults to `base`) and an on-prem builder url and token, this tool can download all packages in the origin and channel from the public Chef Habitat builder that the on-prem instance does not already have and upload them to the on-prem builder.

This performs a pre-flight check to ensure that you do not have local packages in the channel that are not in the same channel on bldr.habitat.sh. If there are, these local packages must be demoted.

## Package List Options

Optionally, one can specify a `--package-list` with a value of either `habitat` or `builder`. Rather than syncing all of the latest packages in the origin/channel, this will sync a predefined list of packages:

- **`habitat`**: Syncs all packages included in a habitat release (CLI, supervisor, studio, etc.)
- **`builder`**: Syncs all packages needed to run an on-prem builder instance

Note that when providing a `--package-list`, the above pre-flight check is not performed.

## Native Packages

Some Habitat packages include native binaries and libraries that are platform-specific. When working with native packages:
- Ensure your target architecture matches the packages you're syncing
- Consider using `--target` flag to specify the correct architecture (x86_64-linux, x86_64-windows, etc.)
- Native packages may require additional system dependencies on the target systems

This tool can also be used to generate a list of packages without actually syncing them.

If for any reason, you end up in a state where packages were bulk uploaded and promoted to the wrong channel, one can use the `--idents-to-promote` option and provide a file with newline separated package identifiers that will be demoted from all non-unstable channels and promoted to the specified channel.

## Usage

Install this package with:

```
sudo hab pkg install habitat/pkg-sync
```

Examples:

Note that the public builder tokens used in the examples below must be associated with a valid license key. See [these instructions](../docs-chef-io/content/habitat/on_prem_builder/packages/bootstrap_core_packages.md#add-a-license-key) on entering a license key.

Sync all the latest core packages from the base channel that you do not already have from the public builder and upload them to your on-prem builder instance.

```
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --origin core --channel base --public-builder-token <your_public_Builder_instance_token> --private-builder-token <your_private_Builder_instance_token>
```

Sync all the latest Habitat release packages from the public builder and upload them to your on-prem builder instance.

```
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel base --package-list habitat --public-builder-token <your_public_Builder_instance_token> --private-builder-token <your_private_Builder_instance_token>
```

Generate a list of all base packages in the core origin.

```
hab pkg exec habitat/pkg-sync pkg-sync --generate-airgap-list --origin core --channel base --public-builder-token <your_public_Builder_instance_token>
```

These lists can be used with `hab pkg download` to download the hart files from builder:

```
hab pkg download -u https://bldr.habitat.sh -z <your_public_Builder_instance_token> --target x86_64-linux --channel base --file package_list_x86_64-linux.txt --download-directory builder_bootstrap
hab pkg download -u https://bldr.habitat.sh -z <your_public_Builder_instance_token> --target x86_64-windows --channel base --file package_list_x86_64-windows.txt --download-directory builder_bootstrap
```

You could then copy the `--download-directory` contents to an airgapped builder and use `hab pkg bulkupload` to upload them:

```
export HAB_AUTH_TOKEN=<your_on-prem_Builder_instance_token>
hab pkg bulkupload --url https://your-builder.tld --channel base --auto-create-origins builder_bootstrap/
```

Promote packages that are in the base channel on the SaaS builder to that same channel on your local on-prem builder instance:

```
# Generate a list of all the latest base package identifiers
hab pkg exec habitat/pkg-sync pkg-sync --channel base --origin core --generate-airgap-list --public-builder-token <your_public_Builder_instance_token>
# Provide that list to --idents-to-promote so that any of those packages that exist on an on-prem instance are demoted from all non-unstable channels and promoted to base
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel base --private-builder-token <your_private_Builder_instance_token> --idents-to-promote package_list_x86_64-linux.txt
hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel base --private-builder-token <your_private_Builder_instance_token> --idents-to-promote package_list_x86_64-windows.txt
```

Note that the public builder tokens used in the examples above must be associated with a valid license key. See [these instructions](../docs-chef-io/content/habitat/on_prem_builder/packages/bootstrap_core_packages.md#add-a-license-key) on entering a license key.