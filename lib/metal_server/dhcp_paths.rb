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

require 'sinja'
require 'tmpdir'
require 'open3'

module MetalServer
  MANAGED_FILE_COPYRIGHT = <<~TEXT
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
# This file has been rendered by OpenFlightHPC - Metal Server
# Any changes to this file maybe lost
#
  TEXT

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
    def index
      Dir.glob(glob_regex)
         .select { |p| match_regex.match?(p) }
         .map { |p| match_regex.match(p)[:id].to_i }
         .max || 0
    end

    # Deprecated: Use index
    def id
      index
    end

    private

    def glob_regex
      DhcpPaths.new(base, '*').join
    end

    def match_regex
      /\A#{DhcpPaths.new(base, '(?<id>[\d]+)').join}\Z/
    end
  end

  DhcpIncluder = Struct.new(:base, :index) do
    def write_include_files
      write_include_subnets
    end

    def write_include_subnets
      FileUtils.mkdir_p File.dirname(paths.include_subnets)
      subnets = subnet_paths
      if subnets.empty?
        FileUtils.touch paths.include_subnets
      else
        includes = subnets.map { |p| File.basename(p) }
                          .map { |n| "include \"../#{n}\";" }
                          .join("\n")
        File.write paths.include_subnets, <<~CONF
          #{MANAGED_FILE_COPYRIGHT}

          #{includes}
        CONF
      end
    end

    private

    def paths
      @paths ||= DhcpPaths.new(base, index)
    end

    def subnet_paths
      Dir.glob(paths.subnet_conf('*'))
    end
  end

  class DhcpRestorer
    include FlightConfig::Reader
    include FlightConfig::Updater
    include FlightConfig::Deleter

    def self.write_current_master_config(base)
      cur_index = DhcpCurrent.new(base).index
      paths = DhcpPaths.new(base, cur_index)
      FileUtils.mkdir_p File.dirname(paths.master_include)
      if cur_index == 0
        FileUtils.rm_f  paths.master_include
        FileUtils.touch paths.master_include
      else
        File.write paths.master_include, <<~CONF
          #{MANAGED_FILE_COPYRIGHT}

          include "#{paths.include_subnets}";
        CONF
      end
    end

    def self.backup_and_restore_on_error(base)
      # Tries to create a new restorer as this prevents multiple running at the same time
      create(base).tap do |restorer|
        begin
          # Set the base paths
          base_old_dir = restorer.old_paths.join
          base_tmp_dir = Dir.mktmpdir(restorer.old_index.to_s + '--', File.dirname(base_old_dir))
          base_new_dir = restorer.new_paths.join

          # Ensures both the old and new directories exist
          FileUtils.mkdir_p(base_old_dir)
          FileUtils.mkdir_p(base_new_dir)

          # Copy the old files to the new directory
          Dir.each_child(base_old_dir) do |old|
            FileUtils.cp_r(File.expand_path(old, base_old_dir), base_new_dir)
          end

          # Intentionally break old absolute paths by moving the directory
          # Only relative paths should be used
          Dir.each_child(base_old_dir) do |old|
            FileUtils.mv(File.expand_path(old, base_old_dir), base_tmp_dir)
          end

          # Write the new master config
          write_current_master_config(base)

          # Yield control to the updater to preform the system commands
          yield(restorer) if block_given?

          # Remove the old and tmp directories
          Dir.rmdir base_old_dir
          FileUtils.rm_rf base_tmp_dir
        ensure
          # Ensure the restorer object clears it self
          FileUtils.rm_f restorer.path

          # Assume the update went wrong if the tmp files still exist
          # rescue should not be used as it will miss Interrupt and
          # other Exceptions
          if Dir.exists?(base_tmp_dir)
            Dir.each_child(base_tmp_dir) do |tmp|
              FileUtils.mv File.expand_path(tmp, base_tmp_dir), base_old_dir
            end

            Dir.rmdir base_tmp_dir
            FileUtils.rm_rf base_new_dir
          end
        end
      end
    ensure
      # Set the master DHCP config to the current version!
      # This is required for fail over
      self.write_current_master_config(base)
    end

    def self.path(base)
      File.join(base, 'dhcp-update.conf')
    end

    private_class_method

    def self.existing_dhcp_each_child(base_old_dir, &b)
      if Dir.exists? base_old_dir
      end
    end

    attr_reader :old_index, :new_index

    def initialize(*a)
      super
      @old_index = DhcpCurrent.new(base).id
      @new_index = @old_index + 1
    end

    def base
      __inputs__[0]
    end

    def new_paths
      @new_paths ||= DhcpPaths.new(base, new_index)
    end

    def old_paths
      @old_paths ||= DhcpPaths.new(base, old_index)
    end
  end

  class DhcpValidationError < Sinja::BadRequestError; end

  class DhcpOfflineError < Sinja::HttpError
    MESSAGE = <<~ERROR.squish
      The DHCP entires can not be updated as the DHCP server is
      not currently running. Please contact your system administrator
      for further assistance.
    ERROR

    def initialize(msg = MESSAGE)
      super(500, msg)
    end
  end

  class HandledDhcpRestartError < Sinja::BadRequestError
    MESSAGE = <<~ERROR.squish
      The DHCP server failed to restart and has been rolled back
      to its last working state. The DHCP config syntax was
      successfully validated before the restart commenced.
    ERROR

    def initialize(msg = MESSAGE)
      super
    end
  end

  class UnhandledDhcpRestartError < Sinja::HttpError
    MESSAGE = <<~ERROR.squish
      An error has occurred whilst restarting the DHCP server. DHCP
      is likely offline as a result of this error. Please contact your
      system administrator for further assistance.
    ERROR

    def self.with_output(output)
      new(<<~ERROR)
        #{MESSAGE}

        Output:
        #{output}
      ERROR
    end

    def initialize(msg = MESSAGE)
      super(500, msg)
    end
  end

  module DhcpUpdater
    def self.update!(base)
      raise DhcpOfflineError unless is_running?

      DhcpRestorer.backup_and_restore_on_error(base) do |restorer|
        # Yield control to the API to preform the updates
        yield if block_given?
        validate_or_error
        restart_or_error
      end
    rescue FlightConfig::CreateError
      raise Sinja::ConflictError, <<~ERROR.squish
        A DHCP update has already been started. Concurrent updates
        are not currently supported
      ERROR
    rescue UnhandledDhcpRestartError
      # Attempt a second restart if the server is offline
      restart_or_error
      raise HandledDhcpRestartError
    end

    def self.is_running?
      _, status = Open3.capture2e(Figaro.env.dhcpd_is_running_command)
      status.to_i == 0
    end

    def self.validate_or_error
      cmd = Figaro.env.validate_dhcpd_command
      output, status = Open3.capture2e(cmd)
      return if status.to_i == 0
      raise DhcpValidationError, <<~ERROR
        Updating DHCP settings has failed as the config failed validation.
        The new configuration has been discarded.

        Output from: #{cmd}

        #{output}
      ERROR
    end

    def self.restart_or_error
      output, status = Open3.capture2e(Figaro.env.restart_dhcpd_command)
      return if status.to_i == 0
      raise UnhandledDhcpRestartError.with_output(output)
    end
  end
end

