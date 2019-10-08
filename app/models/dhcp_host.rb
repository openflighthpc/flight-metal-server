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

class DhcpHost < FileModel
  class << self
    def path(subnet, name)
      File.join(content_base_path, "dhcp-hosts/#{subnet}.subnet/etc/#{name}.yaml")
    end

    def type
      'dhcp-hosts'
    end
  end

  def subnet
    __inputs__[0]
  end

  def name
    __inputs__[1]
  end

  def id
    "#{subnet}/#{name}"
  end

  def system_path
    MetalServer::DhcpPaths.current(DhcpBase.path).host_conf(subnet, name)
  end

  def filename
    File.dirname(system_path)
  end

  def read_dhcp_subnet
    DhcpSubnet.read(subnet, registry: __registry__)
  end
end

