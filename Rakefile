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

