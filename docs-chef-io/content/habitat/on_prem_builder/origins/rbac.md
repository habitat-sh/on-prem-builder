+++
title = "Configure origin membership and role-based access control"

[menu]
  [menu.habitat]
    title = "Origin membership and RBAC"
    identifier = "habitat/on-prem-builder/origins/rbac"
    parent = "habitat/on-prem-builder/origins"
    weight = 10
+++

Role-based access control (RBAC) provides your organization with better operational safety by letting you assign specific levels of access to each user that belongs to an origin. With RBAC in place, existing standard origin 'members' from earlier versions are assigned the 'Maintainer' role. This role has similar permissions of the previous generic 'member' role, and the areas of difference are detailed below. The origin owner role remains unchanged.

When you join or create an origin, Chef Habitat Builder identifies your personal access token and assigns it a membership role for that origin. Your membership role defines the level of access that you have to the resources in an origin. By default, you're assigned the "read-only" role when you join an origin, and you're assigned the 'owner' role when you create an origin.

## Prerequisites

- [Download and install the Chef Habitat CLI](/habitat/install_habitat/)
- [Create a Chef Habitat Builder account]()
- [Generate a personal access token]()
- [Create an origin](./create_an_origin) or accept an invitation to an existing origin
- [Get origin keys](./origin_keys)

## Origin roles

Chef Habitat Builder has the following RBAC origin member roles:

Read-Only
: This user can read an origin's packages, channels, origin membership, jobs, keys, integrations, invitations, roles, settings but cannot add to, change, or delete anything else in the origin, including uploading packages and inviting users to the origin. Read-Only is the default membership role for users joining the origin.

Member
: In addition to read-only access, an origin 'Member' can upload and build packages in the 'unstable' channel, but they cannot promote packages to other channels.

Maintainer
: Existing origin 'members' are now 'Maintainers'. This role has full read and write access to packages, channels, origin membership, jobs, integrations, invitations, settings. However, the 'Maintainer' role is more limited than the past role, in that 'Maintainers' only have read access to packages, channels, origin membership, jobs, keys, integrations, and settings. Origin 'Maintainers' can read origin membership roles and see and send invitations, but they cannot otherwise change origin membership--their own or anybody else's. Finally, 'Maintainers' can neither read nor write origin secrets.

Administrator
: In addition to 'Maintainer' access, the 'Administrator' role adds the missing privileges for writing origin keys and membership roles, as well as for reading and writing origin secrets. Administrators have full read and write access to packages, channels, origin membership, jobs, keys, integrations, invitations, roles, secrets, settings.

Owner
: As in the past, the origin 'Owner' has full read and write access to the origin. Only Owners can delete the origin or transfer ownership to another member.

### Comparison of RBAC Member Roles and Actions

| Action | Read-Only | Member | Maintainer | Administrator | Owner |
|---------|-------|-------|-------|-------|-------|
| **Packages** |
| View packages | Y | Y | Y | Y | Y |
| Upload packages to `unstable` | N | Y | Y | Y | Y |
| Promote packages from `unstable` | N | N | Y | Y | Y |
| **Build Jobs** |
| View build jobs | Y | Y | Y | Y | Y |
| Trigger `unstable` build job | N | Y | Y | Y | Y |
| **Channels** |
| View channels | Y | Y | Y | Y | Y |
| Add/Update/Delete channels | N | N | Y | Y | Y |
| **Origin Keys** |
| View keys | Y | Y | Y | Y | Y |
| Add/Update/Delete keys | N | N | N | Y | Y |
| **Origin Membership** |
| View origin membership | Y | Y | Y | Y | Y |
| View invitations | Y | Y | Y | Y | Y |
| Send Invitations | N | N | Y | Y | Y |
| Revoke Invitations | N | N | Y | Y | Y |
| **Member Roles** |
| View member roles | Y | Y | Y | Y | Y |
| Update member roles | N | N | N | Y | Y |
| **Origin Settings** |
| View settings | Y | Y | Y | Y | Y |
| Add/Update/Delete settings | N | N | N | Y | Y |
| **Origin Secrets** |
| View secrets | N | N | N | Y | Y |
| Add/Update/Delete secrets | N | N | N | Y | Y |
| **Cloud Integrations** |
| View integrations | Y | Y | Y | Y | Y |
| Add/Update/Delete integrations | N | N | Y | Y | Y |
| **Ownership** |
| Transfer Origin | N | N | N | N | Y |
| Delete Origin | N | N | N | N | Y |

### Manage origin membership

In tandem with the changes to the Builder membership roles, we've also updated the `hab` CLI to support RBAC. We're working on adding role management to the Chef Habitat Builder site, but in the meantime, you'll need to use the CLI for now.

![Manage origin membership](/images/habitat/origin-members.png)

#### Manage origin members

Manage Chef Habitat Builder origin membership with the Chef Habitat CLI, using the [`hab origin invitations`](/habitat/habitat_cli/#hab-origin-invitations) command.

All Chef Habitat Builder users can accept, ignore, and see invitations for their accounts.

View origin invitations:

```bash
hab origin invitations list
```

Accept origin invitations:

```bash
hab origin invitations accept <ORIGIN> <INVITATION_ID>
```

Ignore origin invitations:

```bash
hab origin invitations ignore <ORIGIN> <INVITATION_ID>
```

Send origin membership invitations:

```bash
hab origin invitations send <ORIGIN> <INVITEE_ACCOUNT>
```

Origin administrators and owners can see all pending origin membership invitations:

```bash
hab origin invitations pending <ORIGIN>
```

Origin administrators and owners can rescind an origin membership invitation:

```bash
hab origin invitations rescind <ORIGIN> <INVITATION_ID>
```

Origin owners can transfer origin ownership to another member:

```bash
hab origin transfer [OPTIONS] <ORIGIN> <NEW_OWNER_ACCOUNT>
```

#### Manage membership roles

You can use role based access control (RBAC) from the command line.
An origin `MEMBER_ACCOUNT` is the name used to sign in to Chef Habitat builder. You can find the list of user names on an origin's _Members Tab_. (Builder > Origin > Members)

The RBAC command syntax is:

```bash
hab origin rbac <SUBCOMMAND>
```

The syntax for the `show` subcommand is:

```bash
hab origin rbac show <MEMBER_ACCOUNT> --origin <ORIGIN>
```

See an origin member's RBAC role:

```bash
hab origin rbac show bluewhale --origin two-tier-app
```

The syntax for the `set` subcommand is:

```bash
hab origin rbac set [FLAGS] [OPTIONS] <MEMBER_ACCOUNT> <ROLE> --origin <ORIGIN>
```

Set an origin membership RBAC role with:

```bash
hab origin rbac set bluewhale admin --origin two-tier-app
```
