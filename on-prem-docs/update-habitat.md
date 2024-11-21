# Update Habitat Packages

After a Chef Habitat release, one may want to make the released packages available on an on-prem builder instance. This document lays out the steps to take in order to perform such an update.

## Enable Native Package Support

The habitat packages are now built with updated dependencies from the `LTS-2024` channel instead of the `stable` channel. Some of these package dependencies include `native` packages. In order for an on-prem builder instance to host LTS packages or the latest released `stable` habitat packages including these native package dependencies, that builder instance must be configured to allow native package support. This is done by enabling the `nativepackages` feature and specifying `core` as an allowed native package origin. To do this, an on-prem builder's `/hab/user/builder-api/config/user.toml` file should be edited so that the `[api]` section looks as follows:

```
[api]
features_enabled = "nativepackages"
targets = ["x86_64-linux", "x86_64-linux-kernel2", "x86_64-windows"]
allowed_native_package_origins = ["core"]
```

## Bootstrap Builder with Habitat Packages

To assist in updating the habitat release packages of an on-prem Builder instance, you can install the habitat/pkg-sync package which will download packages from the public [SaaS Builder](https://bldr.habitat.sh) followed by a bulkupload to your on-prem Builder instance(s).

The following snippet illustrates how to refresh the on-prem Builder with a full set of the latest released habitat packages:

    ```bash
    sudo hab pkg install habitat/pkg-sync --channel LTS-2024
    hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --origin core --channel stable --auth <your_public_Builder_instance_token> --package-list habitat
    # You may now have some LTS packages in the stable channel in the on-prem instance
    # so you want to move them.
    # To d oso, first Generate a list of all the latest LTS-2024 package identifiers
    hab pkg exec habitat/pkg-sync pkg-sync --channel LTS-2024 --origin core --generate-airgap-list
    # Next, provide that list to --idents-to-promote so that any of those packages
    # that exist on an on-prem instance are demoted from all non-unstable channels
    # and promoted to LTS-2024
    hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel LTS-2024 --auth <your_public_Builder_instance_token> --idents-to-promote package_list_x86_64-linux.txt
    hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel LTS-2024 --auth <your_public_Builder_instance_token> --idents-to-promote package_list_x86_64-windows.txt
    ```

### Airgapped Environments

Airgapped builder instances must take an alternative approach because pkg-sync will not be able to transfer packages from the public internet to your instance. Instead you will use the `--generate-airgap-list` flag with pkg-sync to build a list of packages that need to be downloaded. Then you will use `hab pkg download` and `hab pkg upload` to download the packages from bldr.habitat.sh and upload them to your instance. Note that `pkg-sync` and `hab pkg download` must be used on a machine with access to the public internet. This will download a bundle you can archive and transfer to your instance. Finally you will use `hab pkg bulkupload` locally on your builder instance to upload the packages into your instance.

The following section illustrates the steps required to refresh an airgapped on-prem Builder with a set of the latest stable habitat packages:

1. Phase 1: download from a machine with internet connectivity

    ```bash
    hab pkg install habitat/pkg-sync --channel LTS-2024
    hab pkg exec habitat/pkg-sync pkg-sync --generate-airgap-list --channel stable --package-list habitat
    hab pkg download --target x86_64-linux --channel stable --file package_list_x86_64-linux.txt --download-directory habitat_packages
    hab pkg download --target x86_64-windows --channel stable --file package_list_x86_64-windows.txt --download-directory habitat_packages
    rm package_list_x86_64-*
    hab pkg exec habitat/pkg-sync pkg-sync --generate-airgap-list --origin core --channel LTS-2024
    ```

    Archive the contents of `habitat_packages`, `package_list_x86_64-linux.txt`, and `package_list_x86_64-windows.txt`. Copy and extract to the builder instance

1. Phase 2: bulkupload locally on the builder instance and move LTS packages from `stable` to `LTS-2024`

    ```bash
    export HAB_AUTH_TOKEN=<your_on-prem_Builder_instance_token>
    hab pkg bulkupload --url https://your-builder.tld --channel stable --auto-create-origins habitat_packages/
    hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel LTS-2024 --auth <your_public_Builder_instance_token> --idents-to-promote package_list_x86_64-linux.txt
    hab pkg exec habitat/pkg-sync pkg-sync --bldr-url https://your-builder.tld --channel LTS-2024 --auth <your_public_Builder_instance_token> --idents-to-promote package_list_x86_64-windows.txt
    ```
