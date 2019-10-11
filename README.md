[![Build Status](https://travis-ci.org/openflighthpc/metal-server.svg?branch=master)](https://travis-ci.org/openflighthpc/metal-server)

# Metal Server

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
* Ruby:         2.6+ [Possible ruby 2.x as the `backports` gem is being used]
* Yum Packages: gcc

### Manual installation

Start by cloning the repo, adding the binaries to your path, and install the gems. This guide assumes the `bin` directory is on your `PATH`. If you prefer not to modify your `PATH`, then some of the commands need to be prefixed with `/path/to/app/bin`.

```
git clone https://github.com/openflighthpc/metal-server
cd metal-server

# Add the binaries to your path, which will be used by the remainder of this guide
export PATH=$PATH:$(pwd)/bin
bundle install --without development test --path vendor

# The following command can be ran without modifying the PATH variable by
# prefixing `bin/` to the commands
bin/bundle install --without development test --path vendor
```

### Configuration

The application needs the following configuration values in order to run. These can either be exported into your environment or directly set in `config/application.yaml`.

```
# Either set them into the environment
export app_base_url=http://example.com
export jwt_shared_secret=<keep-this-secret-safe>

# Or hard code them in the config file:
vim config/application.yaml
```

## Starting the Server

This application ships with `unicorn` as it load balancer and will automatically scale the number processes available for machines. `unicorn` also recovers from failures if something goes wrong from within the application.

Run the following to start the unicorn daemon process:

```
unicorn -c unicorn.rb -p 80 -E production -D
```

\*NOTE: If the application is running behind `apache` and `nginx`, it will need to be proxied to another port. The default port is `8080`.

### Issues Starting the Server

If the above command raises a `Figaro::MissingKeys` error than the server has been missed configured and cannot be start. Please refer [configuration](#Configuration) for further assistance.

The next place to check when debugging server issues is the `stderr` log. The logs location depends on how the application has been configured, but the following will work for the default production environment:

```
tail -f log/stderr.log
```

### Running the Application Behind a Reverse Proxy

As this is a `unicorn` application, it has been designed to server fast clients with low latency. Therefore it should be located behind a reverse proxy such as `nginx` or `apache`.

[Refer here for more details](docs/ssl_and_reverse_proxy.md)

### Basic Development Environment

For development purposes, the application can be started in a single threaded `unicorn` process on port `8080`:

```
unicorn
```

Or the underlining rack app can be be started with `rackup`:

```
rackup -p <port> -o 0.0.0.0
```

## Stopping The Application

The application should be shut down gracefully as it modifies external services. Shutting down the application abruptly may result in a miss configuration of the DHCP server.

[Refer here for how to shutdown the server gracefully](docs/stopping_the_application.md)

## Authentication

The API requires all requests to carry with a [jwt](https://jwt.io). Within the token either `user: true` or `admin: true` needs to be set. This will authenticate with either `user` or `admin` privileges respectively. Admins have full access to the API where users can only make `GET` requests.

The following `rake` tasks are used to generate tokens with 30 days expiry. Tokens from other sources will be accepted as long as they:
1. Where signed with the same shared secret,
2. Set either `user: true` or `admin: true` in the token body, and
3. An [expiry claim](https://tools.ietf.org/html/rfc7519#section-4.1.4) has been made.

As the shared secret is environment dependant, the `RACK_ENV` must be set within your environment.

```
# Set the rack environment
export RACK_ENV=production

# Generate a admin token:
rake token:admin

# Generate a user token
rake token:user
```

### Browser Cookie

It is recommended that all requests are made with the `Authorization: Bearer ...` header set. The authorization header is the canonical source for the `jwt`, however a browser `cookie` called `Bearer` can be used as a fallback. This is an unsupported feature and may change without notice.

## API Documentation

The API conforms to the [JSON:API](https://jsonapi.org/) specifications with a few additions
that have been flagged.

[Refer here for full API documentation](docs/routes.md)

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
