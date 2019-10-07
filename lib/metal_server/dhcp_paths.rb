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
    def self.current(base)
      new(base, DhcpCurrent.new(base).id)
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

  DhcpCurrent = Struct.new(:base) do
    def id
      Dir.glob(glob_regex)
         .select { |p| match_regex.match?(p) }
         .map { |p| match_regex.match(p)[:id].to_i }
         .max || 0
    end

    private

    def glob_regex
      DhcpPaths.new(base, '*').include_subnets
    end

    def match_regex
      /\A#{DhcpPaths.new(base, '(?<id>[\d]+)').include_subnets}\Z/
    end
  end

  class DhcpUpdater
    include FlightConfig::Reader
    include FlightConfig::Updater
    include FlightConfig::Deleter

    def self.modify_and_restart_dhcp!(base)
      # Tries to create a new Updater as this prevents multiple running at the same time
      create(base).tap do |updater|
        begin
          # noop
        ensure
          FileUtils.rm_f updater.path
        end
      end
    end

    def self.path(base)
      File.join(base, 'dhcp-update.conf')
    end

    # TODO: Properly set the new and old path versions
    def old_paths
      @old_paths ||= DhcpPaths.current(base)
    end

    def new_paths
      @new_paths ||= DhcpPaths.new(base, 'new')
    end
  end
end

