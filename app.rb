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

require 'sinatra/base'
require 'sinatra/jsonapi'

class UploadApp < Sinatra::Base
  get '/' do
    'Recieved a get'
  end

  post '/' do
    'Recieved a post'
  end
end

class App < Sinatra::Base
  register Sinatra::JSONAPI

  helpers do
    def serialize_model(model, options = {})
      options[:is_collection] = false
      options[:skip_collection_check] = true
      super(model, options)
    end
  end

  resource :kickstarts, pkre: /\w+/ do
    helpers do
      def find(id)
        Kickstart.exists?(id) ? Kickstart.read(id) : nil
      end
    end

    show

    get('/:id/upload') do
      raise Sinja::BadRequestError,
            'This is an upload only path. Please POST the file content to this URL'
    end

    post('/:id/upload') do
      binding.pry
    end
  end
end

