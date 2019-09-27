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

# Sinja requires the following headers to always be set otherwise it raises an
# error. However this is more of a pain then anything else, so this middleware
# forces the headers to be set correctly

require 'stringio'

class App
  module Middleware
    class SetContentHeaders
      def initialize(app)
        @app = app
      end

      # Because the app needs to handle uploads for the time being, it must
      # accept `application/octet-stream'. This is an antipattern as a separate
      # server should be handling uploads as this will slow down the server
      #
      # However for the time being the original stream is being cached elsewhere
      # in the environment. This allows the request body to be reset to an empty
      # IO
      def call(env)
        empty_io = Rack::Lint::InputWrapper.new(StringIO.new)
        if env['CONTENT_TYPE'] = 'application/octet-stream'
          env['cached.octet_stream'] = env['rack.input']
          env['rack.input'] = empty_io
          env['CONTENT_TYPE'] = nil
        else
          env['cached.octet_stream'] = empty_io
        end
        env['HTTP_ACCEPT'] = 'application/vnd.api+json'
        @app.call(env)
      end
    end
  end
end
