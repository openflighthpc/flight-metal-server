# OpenFlight Tools

Manage Cluster Network Boot and DHCP Files

## Overview

Run the Metal Server for managing the building of bare metal clusters. The server provides
the following file types:

* \<API TYPE\>      : \<Model\>    : \<Description\>
* `kickstarts`    : Kickstart  : Kickstart Files
* `uefis`         : Uefi       : UEFI PXE Boot Configs
* `legacies`      : Legacy     : BIOS PXE Boot Configs
* `kernels`       : Kernel     : Kenerl Images
* `initrds`       : Initrd     : Initial Ram Disks
* `dhcp-subnets`  : DhcpSubnet : DHCP Subnet Configs

The application is comprised of three main components:
1. The base Sinatra app running a JSON API with the above file types,
2. Process load balancing provided by `unicorn` (kinda like `puma`), and
3. Reverse proxying and static file hosting provided by `nginx`.

## Installation

### Preconditions

This application has been designed on:

* OS:    Centos7
* Ruby:  2.6+
* Nginx: 1.12+
* Required Nginx Modules: `--with-http_auth_request_module`,
                        etc...

### Manual installation

Start by cloning the repo, adding the binaries to your path, and install the gems

```
git clone https://github.com/openflighthpc/metal-server
cd metal-server

# Add the binaries to your path, which will be used by the remainder of this guide
export -a PATH=$PATH:$(pwd)/bin
bundle install

# Alternatively append `bin/` to the beginning of the following commands
# Excluding nginx and ruby which are already installed
bin/bundle  ...
bin/rake    ...
bin/unicorn ...
```

Next the application needs to be configured. Refer to the example config file
for a complete list of configuration parameters: `config/application.yaml.example`

Alternatively for a default production ready setup, the `rake configure` command
can be used. This will prompt for the required configuration and generate
the `config/application.yaml` file.

```
rake configure
> What is the url to the server? (https://www.example.com)
....
```

The `rake configure` task will automatically re render the `nginx` configuration
files. These files will need to be re-rendered if `config/application.yaml` is
changed. The `nginx` needs to be restarted.

```
# Re render the nginx configs with the current setup
rake render:nginx

# The configs are rendered to the default epel nginx locations
# nginx can be started using:
nginx

# Restart nginx if it is already running
ngnix -s reload
```

Finally the `unicorn` application needs to be started. This depends on how
the application has been configured. In production, the "api port" should
not be set. This cause `nginx` to server the `api`/`unicorn` using a `unix`
socket.

```
# Start a deamonized unicorn server on the unix socket:
unicorn -c unicorn.rb -D -E production

# Alternatively it can be started on port 8080 for development purposes
# This will only spawn a single worker and is not intended for production
unicorn
```

### Stopping Unicorn
Extract from: http://recipes.sinatrarb.com/p/deployment/nginx_proxied_to_unicorn#label-Stopping+the+server

So now that you're using nginx and unicorn, at some point you might end up asking yourself: How do I stop this thing?

There is an internal unicorn `workers.pid` file that contains the process ID of the unicorn master. It can be used
to gracefully stop the server using `SIGQUIT`

```
cat <configured-temporary-directory>/unicorn/master.pid | xargs kill -QUIT
```

If that doesn't work though, you might want to try:

```
ps -ax | grep unicorn
```

This will output the processes running unicorn, in the first column should be the process id (pid). In order to stop unicorn in it's tracks:

### Less Aggressive Way to Stop Unicorn
Extract from: http://recipes.sinatrarb.com/p/deployment/nginx_proxied_to_unicorn#label-The+Less+Aggressive+Approach+to+Unicorn+Slaying

Unicorn is based upon unix-y forking, the master process can manage the workers, i.e. kill them. Once you have identified the master process, you can send it the WINCH signal. To do this:

```
kill -WINCH <PID>
```

This will have the master process “instruct” its workers to die off when they are finished. This should allow for a safer completion state.

Once all the workers are finished and dead, the unicorn master will be the only unicorn process left. You can now instruct it to die off.

```
kill -QUIT <PID>
```

Checking again as above, you should no longer see any unicorn processes.  

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
