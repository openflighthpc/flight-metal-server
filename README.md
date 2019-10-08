# OpenFlight Tools

Manage Cluster Network Boot and DHCP Files

## Overview

Run the Metal Server for managing the building of bare metal clusters. The server provides
the following file types:

The application is comprised of two main components:
1. The base Sinatra app running a JSON API with the above file types, and
2. Process load balancing provided by `unicorn` (as opposed to `puma`)

## Installation

### Preconditions

The following are required to run this application:

* OS:           Centos7
* Ruby:         2.6+ [Possible ruby 2.x?]
* Yum Packages: gcc

### Manual installation

Start by cloning the repo, adding the binaries to your path, and install the gems

```
git clone https://github.com/openflighthpc/metal-server
cd metal-server

# Add the binaries to your path, which will be used by the remainder of this guide
export -a PATH=$PATH:$(pwd)/bin
bundle install --without development test --path vendor

# Alternatively append `bin/` to the beginning of the following commands
# Skip export
bin/bundle install --without --development test --path vendor
```

### Configuration

TBA

### Intro To Unicorn

TBA

#### Starting Unicorn

TBA

### Stopping The Application

The application should be shut down gracefully as it modifies external
services. Shutting down the application abruptly may result in a miss
configuration of the DHCP server.

[Refer here for how to shutdown the server gracefully](docs/stopping_the_application.md)

## Operation

### Generating Tokens

The server requires the `Authorization Bearer` header to be set with either a `user` or `admin` token. Broadly,
users can read from the server and admins can write. All tokens are valid for 30 days.

```
# Generate a admin token:
rake token:admin

# Generate a user token
rake token:user
```

When testing through a browser, the token can also be set in a `cookie` called `bearer`.

### API Information

The API is typically mounted onto `nginx` something along the lines of `https://www.example.com/api/...`,
however this will depend on how the application has been configured. It conforms to the JSONAPI
standard where the `id` can be alaphanumeric.

NOTE: `nginx` assumes that unicorn is listed under the `api` path.

The valid types for the API are listed above and must be pluralized. The supported requests are:

* GET   <leader>/api/<type>       # Index a type of file
* GET   <leader>/api/<type>/<id>  # Show a file metadata
* POST  <leader>/api/<type>/<id>  # Create the matadata entry but does not upload the file

### Other Application Paths

The following routes exist in the application but do not follow the JSONAPI standard:

* GET   <leader>/download/<type>/<filename> # Download a file from `nginx`
* POST  <leader>/api/<type>/<id>/upload     # Upload a file to an existing metadata entry
* GET   <leader>/api/authorize/download/<type>/<filepath> # Used internally by `nginx`

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

Metal Server is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Based on a work at [https://github.com/openflighthpc/openflight-tools](https://github.com/openflighthpc/openflight-tools).

This content and the accompanying materials are made available available
under the terms of the Creative Commons Attribution-ShareAlike 4.0
International License which is available at [https://creativecommons.org/licenses/by-sa/4.0/](https://creativecommons.org/licenses/by-sa/4.0/),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Metal Server is distributed in the hope that it will be useful, but
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF
TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR
PURPOSE. See the [Creative Commons Attribution-ShareAlike 4.0
International License](https://creativecommons.org/licenses/by-sa/4.0/) for more
details.
