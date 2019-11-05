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
require 'open3'

require 'metal_server/managed_file'
require 'metal_server/restorer'

module MetalServer
  class NamedOfflineError < Sinja::HttpError
    MESSAGE = <<~ERROR.squish
      Can not proceed with this request as the named server is not currently
      running. Please contact your system administrator for further assistance.
    ERROR

    def self.raise_if_offline
      _, status = Open3.capture2e(Figaro.env.named_is_running_command)
      return if status == 0
      raise new
    end

    def initialize(msg = MESSAGE)
      super(500, msg)
    end
  end

  class NamedValidationError < Sinja::BadRequestError
    def self.raise_unless_valid
      cmd = Figaro.env.namedconf_is_valid_command
      output, status = Open3.capture2e(cmd)
      raise_error(cmd, output) unless status == 0
    end

    private_class_method

    def self.raise_error(cmd, output)
      raise self, <<~ERROR
        Updating named has failed as the config isn't valid.
        The new configuration has been discarded.

        Validation Command: #{cmd}

        #{output}
      ERROR
    end
  end

  class UnhandledNamedRestartError < Sinja::HttpError
    MESSAGE = <<~ERROR.squish
      An error has occurred whilst restarting the BIND server. DNS has likely
      been affected as a result of this error. Please contact your system
      administrator for further assistance.
    ERROR

    def self.raise_unless_restarts
      _, status = Open3.capture2e(Figaro.env.named_restart_command)
      return if status == 0
      raise self
    end

    def initialize(msg = MESSAGE)
      super(500, msg)
    end
  end

  class HandledNamedRestartError < Sinja::BadRequestError
    MESSAGE = <<~ERROR.squish
      The BIND server failed to restart after modifying the config/zones.
      The system has been successfully rolledback to the last working state.
    ERROR

    def initialize(msg = MESSAGE)
      super
    end
  end

  module NamedUpdater
    def self.update
      # Ensure named is running
      NamedOfflineError.raise_if_offline

      Restorer.backup_multiple(Named.zone_dir, Named.config_dir) do
        # Yield control to the caller to update the configs
        yield if block_given?

        # Rewrites the subnets linking file
        write_subnets_file

        # Validate the configs
        NamedValidationError.raise_unless_valid

        # Restart the named server
        UnhandledNamedRestartError.raise_unless_restarts
      end
    rescue UnhandledNamedRestartError
      # Attempts a second restart on fallback
      UnhandledNamedRestartError.raise_unless_restarts
      raise HandledNamedRestartError
    end

    def self.write_subnets_file
      includes = Dir.glob(Named.config_join('*'))
                    .map { |c| "include \"#{c}\";" }
                    .join("\n")
      FileUtils.mkdir_p File.dirname(Named.subnets_path)
      File.write Named.subnets_path, <<~CONF
        #{MANAGED_FILE_COPYRIGHT}

        #{includes}
      CONF
    end
  end
end

