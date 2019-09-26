# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Metal Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Metal Server is distributed in the hope that it will be useful, but
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
# For more information on Flight Metal Server, please visit:
# https://github.com/openflighthpc/flight-metal-server
#===============================================================================

require 'sinatra/base'
require 'sinatra/jsonapi'

require 'app/models/kickstart'

require 'app/serializers/kickstart_serializer'

class App < Sinatra::Base
  register Sinatra::JSONAPI

  get('/status', provides: :json) { 'OK' }

  helpers do
    def serialize_model(model, options = {})
      options[:is_collection] = false
      options[:skip_collection_check] = true
      super(model, options)
    end
  end

  resource :kickstarts do
    helpers do
      def find(name)
        Kickstart.new(name)
      end
    end

    show
  end
end

