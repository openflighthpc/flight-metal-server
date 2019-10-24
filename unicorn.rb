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

# Grabs its directories using a subshell. This means the master process doesn't
# getting polluted with these changes
require 'open3'
output, status = Open3.capture2("#{__dir__}/bin/rake unicorn_dirs")
pid_file, log_dir = if status.to_i == 0
  output.split("\n")
else
  $stderr.puts output
  exit 1
end

# Set the working directory
@dir = __dir__
worker_processes Etc.nprocessors + 1
working_directory @dir

timeout 30

# Set process id path
FileUtils.mkdir_p File.dirname(pid_file)
pid pid_file

# Set log file paths
FileUtils.mkdir_p log_dir
stdout_path File.join(log_dir, 'stdout.log')
stderr_path File.join(log_dir, 'stderr.log')

