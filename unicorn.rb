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

#
# Based of Sinatra + Nginx + Unicorn recipe:
# http://recipes.sinatrarb.com/p/deployment/nginx_proxied_to_unicorn
#

# Manually load in the configuration doc as Figaro has not setup the ENV yet
require 'yaml'
config_path   = File.read File.join(__dir__, 'config/application.yaml')
content_base  = YAML.load(config_path, symbolize_keys: true)[:content_base_path] || \
                  ENV['content_base_path'] || \
                  raise('The "content_base_path" has not been set! See README.md for assistance')
tmp_dir = File.expand_path('tmp/unicorn', content_base)

# Set the working directory
@dir = __dir__

worker_processes Etc.nprocessors + 1
working_directory @dir

timeout 30

listen File.expand_path('api.sock', tmp_dir)

# Set process id path
pid File.expand_path('master.pid', tmp_dir)

# Set log file paths
FileUtils.mkdir_p File.expand_path('log', tmp_dir)
stderr_path File.expand_path('log/stderr.log', tmp_dir)
stdout_path File.expand_path('log/stdout.log', tmp_dir)

