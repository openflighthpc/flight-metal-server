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
      join('hosts', "subnet.#{name}.conf")
    end

    def host_conf(subnet, name)
      join('hosts', "#{subnet}", "#{name}.conf")
    end
  end

  # TODO: Review the use of DhcpCurrent
  # It was originally implemented when the indexing was being increment on each edit, but this
  # breaks the DHCP absolute paths. Relative paths do not work well with DHCP as they are dependent
  # on the current working directory which is unpredictable. Instead the index will always be
  # `current`
  DhcpCurrent = Struct.new(:base) do
    def index
      'current'
    end

    # Deprecated: Use index
    def id
      index
    end
  end

  class DhcpRestorer
    include FlightConfig::Reader
    include FlightConfig::Updater
    include FlightConfig::Deleter

    def self.backup_and_restore_on_error(base)
      # Tries to create a new restorer as this prevents multiple running at the same time
      create(base).tap do |restorer|
        begin
          # Set the base paths
          base_dir = restorer.paths.join
          base_tmp_dir = Dir.mktmpdir(File.dirname(base_dir))

          # Ensures the directory exists
          FileUtils.mkdir_p(base_dir)

          # Copy the original files to the temporary directory
          Dir.each_child(base_dir) do |name|
            FileUtils.cp_r(File.expand_path(name, base_dir), base_tmp_dir)
          end

          # Yield control to the updater to preform the system commands
          yield(restorer) if block_given?

          # Remove the temporary directory on success
          FileUtils.rm_rf base_tmp_dir
        ensure
          # Restore from the temporary directory if it still exists
          # This indicates something went wrong and works with Interrupt
          if Dir.exists?(base_tmp_dir)
            FileUtils.rm_rf base_dir
            FileUtils.mkdir_p base_dir

            Dir.each_child(base_tmp_dir) do |tmp|
              FileUtils.mv File.expand_path(tmp, base_tmp_dir), base_dir
            end

            FileUtils.rmdir base_tmp_dir
          end

          # Ensure the restorer object clears it self
          FileUtils.rm_f restorer.path
        end
      end
    end

    def self.path(base)
      File.join(base, 'dhcp-update.conf')
    end

    private_class_method

    def self.existing_dhcp_each_child(base_old_dir, &b)
      if Dir.exists? base_old_dir
      end
    end

    def base
      __inputs__[0]
    end

    def paths
      @paths ||= DhcpPaths.current(base)
    end
  end

  DhcpIncluder = Struct.new(:base, :index) do
    def write_include_files
      write_include_subnets
      write_include_hosts
    end

    def write_include_subnets
      FileUtils.mkdir_p File.dirname(paths.include_subnets)
      subnets = subnet_paths
      if subnets.empty?
        File.write paths.include_subnets, ''
      else
        includes = subnets.map { |p| "include \"#{p}\";" }.join("\n")
        File.write paths.include_subnets, <<~CONF
          #{MANAGED_FILE_COPYRIGHT}

          #{includes}
        CONF
      end
    end

    def write_include_hosts
      subnets.each do |subnet|
        hosts_path = paths.subnet_hosts(subnet)
        FileUtils.mkdir_p File.dirname(hosts_path)
        hosts = hosts_paths(subnet)
        if hosts.empty?
          File.write hosts_path, ''
        else
          includes = hosts.map { |p| "include \"#{p}\";" }.join("\n")
          File.write paths.subnet_hosts(subnet), <<~CONF
            #{MANAGED_FILE_COPYRIGHT}

            #{includes}
          CONF
        end
      end
    end

    private

    def paths
      @paths ||= DhcpPaths.new(base, index)
    end

    def subnet_paths
      @subnet_paths ||= Dir.glob(paths.subnet_conf('*'))
    end

    def subnets
      subnet_paths.map { |p| File.basename(p).chomp('.conf') }
    end

    def hosts_paths(subnet)
      Dir.glob(paths.host_conf(subnet, '*'))
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

        # Writes the new includes excluding the master config
        DhcpIncluder.new(base, DhcpCurrent.new(base).index).write_include_files

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

