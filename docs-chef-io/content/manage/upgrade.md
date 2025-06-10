+++
title = "Upgrade Chef Habitat Builder on-prem"

[menu]
  [menu.habitat]
    title = "Upgrade"
    identifier = "habitat/on-prem-builder/upgrade"
    parent = "habitat/on-prem-builder"
    weight = 20
+++

Chef Habitat Builder on-prem services don't upgrade automatically.
To upgrade the services, use the uninstall script to stop, unload, and remove them.

To upgrade Chef Habitat Builder on-prem, follow these steps:

1. Clone the [`habitat-sh/on-prem-builder`](https://github.com/habitat-sh/on-prem-builder) repository on the computer running Habitat Builder on-prem.

1. Uninstall all Habitat Builder services by running the [uninstall script](https://github.com/habitat-sh/on-prem-builder/blob/main/uninstall.sh):

    ```shell
    sudo ./uninstall.sh
    ```

1. After the services are uninstalled, reinstall them by running the [`install.sh` script](https://github.com/habitat-sh/on-prem-builder/blob/main/install.sh):

    ```shell
    ./install.sh
    ```

{{< note >}}

Running the uninstall script doesn't remove any user data, so you can uninstall and reinstall the services without losing data.

{{< /note >}}
