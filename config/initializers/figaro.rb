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

require 'figaro'

# Loads the configurations into the environment
Figaro.application = Figaro::Application.new(
  environment: (ENV['RACK_ENV'] || 'development').to_sym,
  path: File.expand_path('../application.yaml', __dir__)
)
Figaro.load
      .reject { |_, v| v.nil? }
      .each { |key, value| ENV[key] ||= value }

# Hard sets the app's root directory to the current code base
ENV['app_root_dir'] = File.expand_path('../..', __dir__)
root_dir = ENV['app_root_dir']

# Sets relative defaults to the install location
ENV['content_dir']  ||= File.join(root_dir, 'var')
ENV['log_dir']      ||= File.join(root_dir, 'log')

# Deprecated: Use `content_dir` instead of `content_base_path` for consistency
ENV['content_base_path'] = ENV['content_dir']

Figaro.require_keys 'app_root_dir',
                    'app_base_url',
                    'content_dir',
                    'log_dir',
                    'jwt_shared_secret',
                    'Legacy_system_dir',
                    'Uefi_system_dir',
                    'Kickstart_system_dir',
                    'Kernel_system_dir',
                    'Initrd_system_dir',
                    'validate_dhcpd_command',
                    'restart_dhcpd_command',
                    'dhcpd_is_running_command'

