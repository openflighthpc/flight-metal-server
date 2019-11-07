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

  raise <<~ERROR.chomp unless ENV['RACK_ENV']
    Can not require the application because the RACK_ENV has not been set.
    Please export the env to your enviroment and try again:

    export RACK_ENV=production
  ERROR

  Bundler.require(:default, ENV['RACK_ENV'].to_sym)

  # Turns FakeFS off if running in test mode. The gem isn't installed in production
  FakeFS.deactivate! if ENV['RACK_ENV'] == 'test'
end

task require: :require_bundler do
  require 'config/initializers/active_support'
  require 'config/initializers/figaro'
  require 'config/initializers/models'
  require 'config/initializers/serializers'

  require 'app'
  require 'app/middleware/set_content_headers'
end

# Unicorn gets these in a subshell so it does not have to setup Bundler in the
# master process
task unicorn_dirs: :require do
  puts <<~PATHS.chomp
    #{File.join(ENV['content_dir'], 'etc/master-unicorn.pid')}
    #{ENV['log_dir']}
  PATHS
end

task 'daemon:stop' => :require do
  require 'open3'
  pid_file = File.join(ENV['content_dir'], 'etc/master-unicorn.pid')
  if File.exists?(pid_file)
    pid = File.read(pid_file).chomp.to_i
    Process.kill('WINCH', pid)
    sleep 0.5
    _, status = Open3.capture2e("ps --ppid #{pid}")
    if status.to_i == 0
      raise <<~ERROR.chomp
        Failed to stop the server as the child processes have not exited!
        This could be because:
          * The unicorn server was not daemonized with `-D`, OR
          * A worker process is handling a long request.
      ERROR
    else
      Process.kill('QUIT', pid)
    end
  else
    $stderr.puts 'The server is not currently running!'
  end
end

task console: :require do
  binding.pry
end

task initialize: :require do |t|
  # Sets up the DHCP server
  metal_dhcp = MetalServer::DhcpPaths.current(DhcpBase.path).include_subnets
  main_dhcp = Figaro.env.initialize_dhcp_main_config
  dhcp_regex = /^\s*include\s+"#{Regexp.escape(metal_dhcp)}"\s*;.*$/
  FileUtils.mkdir_p File.dirname(metal_dhcp)
  FileUtils.touch metal_dhcp
  unless File.read(main_dhcp).match?(dhcp_regex)
    include_dhcp = "\ninclude \"#{metal_dhcp}\";"
    File.write(main_dhcp, include_dhcp, mode: 'a')
    puts <<~INFO
      Added the following to: #{main_dhcp}
      #{include_dhcp.squish}

    INFO
  end

  # Sets up the BIND server
  metal_named = Named.subnets_path
  main_named = Figaro.env.initialize_named_main_config
  named_regex = /^\s*include\s+"#{Regexp.escape(metal_named)}"\s*;.*$/
  FileUtils.mkdir_p File.dirname(metal_named)
  FileUtils.touch metal_named
  unless File.read(main_named).match?(named_regex)
    include_named = "\ninclude \"#{metal_named}\";"
    File.write(main_named, include_named, mode: 'a')
    puts <<~INFO
      Added the following to: #{main_named}
      #{include_named.squish}

    INFO
  end
end

task 'token:admin' => :require do
  puts User.new(admin: true).generate_jwt
end

task 'token:user' => :require do
  puts User.new(user: true).generate_jwt
end

