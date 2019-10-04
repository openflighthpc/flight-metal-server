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

require 'erb'

class DhcpSubnet < SingleIDFileModel
  class << self
    attr_writer :dhcp_subnet_include_path

    def dhcp_subnet_include_path
      DhcpSubnet.instance_variable_get(:@dhcp_subnet_include_path) || raise(<<~ERROR.chomp)
        Could not locate the path to the dhcp subnet include config
      ERROR
    end

    def dhcp_subnet_include_template
      File.join(Figaro.env.app_root_dir, 'templates', 'dhcp-subnets.conf')
    end

    def type
      'dhcp-subnets'
    end

    def render_subnets
      FileUtils.mkdir_p File.dirname(dhcp_subnet_include_path)
      template = File.read(dhcp_subnet_include_template)
      rendered = ERB.new(template, nil, '-').result(binding)
      File.write(dhcp_subnet_include_path, rendered)
    end
  end

  def filename
    "subnet.#{id}.conf"
  end

  def read_dhcp_hosts
    DhcpHost.glob_read(id, '*', registry: __registry__)
  end
end

