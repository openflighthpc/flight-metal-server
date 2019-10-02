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

# Figaro sets up the environment once the app has loaded, however unicorn needs
# the temporary directory before then. It will be properly validated once the app
# starts
require 'yaml'
configs = YAML.load(File.read File.join(__dir__, 'config/application.yaml'))

# Set the working directory
@dir = __dir__

# Set the location of temporary files
tmp_dir = configs['temporary_directory'] ||\
  configs[:temporary_directory] ||\
  ENV['temporary_directory'] ||\
  File.join(__dir__, 'tmp')

worker_processes Etc.nprocessors + 1
working_directory @dir

timeout 30

# Create the unicorn directories
FileUtils.mkdir_p File.expand_path('unicorn/log', tmp_dir)

listen File.expand_path('unicorn/api.sock', tmp_dir),
       backlog: 64

# Set process id path
pid File.expand_path('unicorn/master.pid', tmp_dir)

# Set log file paths
stderr_path File.expand_path('unicorn/log/stderr.log', tmp_dir)
stdout_path File.expand_path('unicorn/log/stdout.log', tmp_dir)

