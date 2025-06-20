+++
title = "Create an origin"

[menu]
  [menu.habitat]
    title = "Create an origin"
    identifier = "habitat/on-prem-builder/origins/overview"
    parent = "habitat/on-prem-builder/origins"
    weight = 10
+++

You can create origins in an on-prem Habitat Builder deployment.
[Chef's public Habitat Builder](https://bldr.habitat.sh) doesn't support creating new origins.

## Create an origin in Chef Habitat Builder

To create an origin in Chef Habitat Builder, follow these steps:

1. In Habitat Builder, select **My Origins** in the left navigation menu.

1. On the **My Origins** page, select **Create origin** which opens the **Create New Origin** form.

1. Enter a unique name that you want to associate with your packages.  Chef Habitat will only let you create an origin with a unique name. Some examples that you'll see in Chef Habitat Builder are team names, user names, and abstract concepts.

1. Choose a privacy setting to set as the default for new packages. You can override this setting when uploading individual packages from the CLI or by connecting a plan file that declares a package as private.

   The difference between public and private packages is:

   - Anyone can find and use public packages.
   - Only users with origin membership can find and use private packages.

1. Select **Save and Continue**

    Habitat Builder does the following:

    - Creates your origin.
    - Creates an [origin key pair](../origin_keys).
    - Redirects Chef Habitat Builder to the origin page.

   ![Origin successfully created](/images/habitat/create-origin-done.png)

## Create an origin with the Chef Habitat CLI

To create an origin with the hab CLI, use the [`hab origin create`](/habitat/habitat_cli/#hab-origin-create) command. For example:

- ```bash
  hab origin create <ORIGIN>
  ```

  Habitat creates an origin on the Chef Habitat Builder site.

To create key pair for your origin, see the [origin keys](../origin-keys) documentation.
