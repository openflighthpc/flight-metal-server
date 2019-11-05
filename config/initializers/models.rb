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

require 'flight_config'

module Patches
  module FlightConfigMatcherRegex
    def keys
      @keys ||= Array.new(arity) { |i| "__FLIGHT_CONFIG_MATCH_ARG#{i}__" }
    end

    def regex
      @regex ||= begin
        escaped_path = Regexp.escape klass.new(*keys).path
        regex_path = keys.reduce(escaped_path) do |path, key|
          path.gsub(key, "(?<#{key}>.*)")
        end
        /#{regex_path}/
      end
    end
  end
end

FlightConfig::Globber::Matcher.prepend Patches::FlightConfigMatcherRegex

require 'metal_server/dhcp_paths'

require 'app/model'
require 'app/models/boot_method'
require 'app/models/dhcp_host'
require 'app/models/dhcp_subnet'
require 'app/models/kickstart'
require 'app/models/grub'
require 'app/models/named'
require 'app/models/legacy'
require 'app/models/service'
require 'app/models/user'

Model.content_base_path = Figaro.env.content_base_path

class DhcpBase
  def self.path
    Figaro.env.Dhcp_system_dir
  end
end

User.jwt_shared_secret = Figaro.env.jwt_shared_secret

