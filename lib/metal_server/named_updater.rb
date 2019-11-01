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

  NamedUpdater = Struct.new(:models) do
    def update
      NamedOfflineError.raise_if_offline
    end
  end
end

