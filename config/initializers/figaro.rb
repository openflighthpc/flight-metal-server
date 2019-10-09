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

Figaro.application = Figaro::Application.new(
  environment: 'production',
  path: File.expand_path('../application.yaml', __dir__)
)

Figaro.load.each { |key, value| ENV[key] = value }
ENV['app_root_dir'] ||= File.expand_path('../..', __dir__)

ENV['validate_dhcpd_command']   ||= 'dhcpd -t -cf /etc/dhcp/dhcpd.conf'
ENV['restart_dhcpd_command']    ||= 'systemctl restart dhcpd.service'
ENV['dhcpd_is_running_command'] ||= 'systemctl status dhcpd.service'

Figaro.require_keys 'app_base_url',
                    'app_root_dir',
                    'content_base_path',
                    'default_system_dir',
                    'temporary_directory',
                    'Kernel_system_dir',
                    'Initrd_system_dir'

