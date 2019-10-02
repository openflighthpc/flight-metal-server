# OpenFlight Tools

Manage Cluster Network Boot and DHCP Files

## Overview

Run the Metal Server for managing the building of bare metal clusters. The server provides
the following file types:

* \<API TYPE\>      : \<Model\>    : \<Description\>
* `kickstarts`    : Kickstart  : Kickstart Files
* `uefis`         : Uefi       : UEFI PXE Boot Configs
* `legacy`        : Legacy     : BIOS PXE Boot Configs
* `kernels`       : Kernel     : Kenerl Images
* `initrds`       : Initrd     : Initial Ram Disks
* `dhcp-subnets`  : DhcpSubnet : DHCP Subnet Configs

The application is comprised of three main components:
1. The base Sinatra app running a JSON API with the above file types,
2. Process load balancing provided by `unicorn` (kinda like `puma`), and
3. Reverse proxying and static file hosting provided by `nginx`.

See the `Operation` section for further details

## Installation

### Manual installation

Clone the repository -- you're done!

```
git clone https://github.com/openflighthpc/openflight-tools
```

### From the OpenFlight `yum` repository

1. Set up the `yum` repository on your system.  For production
   releases use `openflight.repo` and for development releases use
   `openflight-dev.repo`:

   ```
   cd /etc/yum.repos.d
   # For production releases
   wget https://openflighthpc.s3-eu-west-1.amazonaws.com/repos/openflight/openflight.repo
   # For development releases
   wget https://openflighthpc.s3-eu-west-1.amazonaws.com/repos/openflight-dev/openflight-dev.repo
   ```

2. Rebuild your `yum` cache:

   ```
   yum makecache
   ```

3. Install the `openflight-tools` RPM with `yum`:

   ```
   yum install openflight-tools
   ```

## Operation

The content in this repository can be installed using the Flight
Runway `flintegrate` tool.  Refer to the [Flight Runway
project](https://github.com/openflighthpc/flight-runway) for more
details.

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Creative Commons Attribution-ShareAlike 4.0 License, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

You should have received a copy of the license along with this work.
If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.

![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

OpenFlight Tools is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Based on a work at [https://github.com/openflighthpc/openflight-tools](https://github.com/openflighthpc/openflight-tools).

This content and the accompanying materials are made available available
under the terms of the Creative Commons Attribution-ShareAlike 4.0
International License which is available at [https://creativecommons.org/licenses/by-sa/4.0/](https://creativecommons.org/licenses/by-sa/4.0/),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

OpenFlight Tools is distributed in the hope that it will be useful, but
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF
TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR
PURPOSE. See the [Creative Commons Attribution-ShareAlike 4.0
International License](https://creativecommons.org/licenses/by-sa/4.0/) for more
details.
