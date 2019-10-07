# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Metal Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Metal Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Metal Server, please visit:
# https://github.com/openflighthpc/metal-server
#===============================================================================

task :require_bundler do
  $: << __dir__
  $: << File.join(__dir__, 'lib')
  ENV['BUNDLE_GEMFILE'] ||= File.join(__dir__, 'Gemfile')

  require 'rubygems'
  require 'bundler'

  if ['development', 'test'].include?(ENV['RACK_ENV'])
    Bundler.setup(:default, :development)
    require 'pry'
    require 'pry-byebug'
    $: << File.expand_path('spec', __dir__)
  else
    Bundler.setup(:default)
  end
end

task require: :require_bundler do
  require 'config/initializers/active_support'
  require 'config/initializers/figaro'
  require 'config/initializers/models'
  require 'config/initializers/serializers'

  require 'app'
  require 'app/middleware/set_content_headers'
end

task 'render:nginx' => :require do
  require 'erb'

  # Renders the default locations
  template = File.read(File.expand_path('templates/nginx-default-locations.conf', __dir__))
  rendered = ERB.new(template, nil, '-').result(binding)
  File.write('/etc/nginx/default.d/metal-server.conf', rendered)

  # Render the Upstream file
  template = File.read(File.expand_path('templates/nginx-http-include.conf', __dir__))
  rendered = ERB.new(template, nil, '-').result(binding)
  File.write('/etc/nginx/conf.d/metal-server.conf', rendered)
end

task :console do
  ENV['RACK_ENV'] = 'development'
  Rake::Task['require'].invoke
  binding.pry
end

task 'token:admin' => :require do
  puts User.new(admin: true).generate_jwt
end

task 'token:user' => :require do
  puts User.new(user: true).generate_jwt
end

task configure: :require_bundler do
  require 'config/initializers/active_support'
  require 'tty-prompt'
  require 'uri'
  require 'figaro'
  require 'securerandom'

  cli = TTY::Prompt.new
  config_path = File.expand_path('config/application.yaml', __dir__)
  configs = if File.exists?(config_path)
    YAML.load(File.read(config_path)).symbolize_keys
  else
    {}
  end

  base_url_regex = /\A(.*)(?=(\/api)\Z)/
  default = if base_url_regex.match? configs[:app_base_url]
    base_url_regex.match(configs[:app_base_url]).captures.first
  else
    'https://www.example.com'
  end
  url = cli.ask("What is the url to the server?", default: default)
  configs[:app_base_url] = URI.join(url, 'api').to_s
  configs[:default_base_download_url] = URI.join(url, 'download').to_s

  default = configs[:content_base_path] || File.expand_path('var/meta', __dir__)
  configs[:content_base_path] = cli.ask(<<~QUESTION.chomp, default: default)
    Which directory should metadata files be stored in?
  QUESTION

  default = configs[:default_system_dir] || File.expand_path('var/www', __dir__)
  configs[:default_system_dir] = cli.ask(<<~QUESTION.chomp, default: default)
    Where should the public directory be located?
  QUESTION

  default = configs[:temporary_directory] || File.expand_path('tmp', __dir__)
  configs[:temporary_directory] = cli.ask(<<~QUESTION.chomp, default: default)
    Which directory should temporary files be stored in?
  QUESTION

  cli.say(<<~DHCP.squish)
    Specify the file path where dhcp entries can be stored.
    This must be included by the system dhcp config.
  DHCP
  default = configs[:dhcp_subnet_include_config_path] || \
              File.expand_path('var/dhcp.conf', __dir__)
  configs[:dhcp_subnet_include_config_path] = cli.ask(<<~QUESTION.chomp, default: default)
    Metal server DHCP config path?
  QUESTION

  first_run = false
  unless configs[:jwt_shared_secret]
    first_run = true
    cli.say('Generating random json web token secret')
    configs[:jwt_shared_secret] = SecureRandom.base64(50)
  end

  if cli.yes?('Use the default system paths for build files?', default: first_run)
    configs[:Legacy_system_dir]      = '/var/lib/tftpboot/pxelinux.cfg'
    configs[:Uefi_system_dir]        = '/var/lib/tftpboot/efi'
    configs[:KernelFile_system_dir]  = '/var/lib/tftpboot/boot'
    configs[:Initrd_system_dir]      = '/var/lib/tftpboot/boot'
  else
    cli.say('The system paths have not been altered unless the public directory has changed')
  end

  port = configs[:api_port]
  bool = port ? true : false
  if cli.yes?('Run the API over TCP/IP instead of unix socket (not recommended)?', default: bool)
    configs[:api_port] = cli.ask("What is the API port number", convert: :int, default: port).to_s
  else
    configs.delete(:api_port)
  end

  File.write(config_path, YAML.dump(configs.stringify_keys))

  cli.say('Rendering the nginx configs...')
  Rake::Task['render:nginx'].invoke
  cli.say('Done! nginx will need to be restarted')
end

