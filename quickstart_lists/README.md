This directory contains 'starter lists' of packages for bootstrapping and syncing on-prem-builders.

Background: Historically we bootstraped on-prem-builders by downloading all the packages in 'core'
for all targets. That amounted to about 15GB, and was both too much and too little, in that many of
the packages weren't needed, and for many patterns (effortless) other origins were needed.

The basic naming pattern is TASK\_ARCH\_CHANNEL. This due to a limitation of the input file
format. The simple newline separated list of package idents doesn't allow for specification of
channel or target architecture inline, so we're using a file naming convention to represent that
information.

The current tasks are
* builder (setting up an on prem builder)
* core_deps (a reduced starter set from core with common build time deps)
* core_full (everything for a particular architecture)
* effortless (starter set for the effortless pattern)

Each is	broken out by the architecture and channel required; to	complete some two downloads, once
from stable and once from unstable will be required.

For example, to	get the	complete effortless infrastructure for linux,
```
hab pkg download --download-directory download_pkgs --channel=unstable --target x86_64-linux  --file  quickstart_lists/effortless_x86_64-windows_unstab\
le
hab pkg download --download-directory download_pkgs --channel=stable --target x86_64-linux  --file  quickstart_lists/effortless_x86_64-windows_stable
```
