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

module MetalServer
  DhcpPaths = Struct.new(:base, :version) do
    # TODO: Make this preform a lookup for the current version of the paths
    def self.current(base)
      new(base, 'current')
    end

    def self.master_include(base)
      File.join(base, 'master-dhcp.conf')
    end

    def master_include
      self.class.master_include(base)
    end

    def join(*a)
      File.join(base, version.to_s, *a)
    end

    def include_subnets
      join('subnets.conf')
    end

    def subnet_conf(name)
      join('subnets', "#{name}.conf")
    end

    # Must be in the same directory as the subnet config. This is to allow relative paths
    def subnet_hosts(name)
      join('subnets', "#{name}.hosts.conf")
    end

    def host_conf(subnet, name)
      join('subnets', "#{subnet}.hosts", "#{name}.conf")
    end
  end
end

