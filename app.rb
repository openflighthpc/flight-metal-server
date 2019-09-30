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

class App < Sinatra::Base
  register Sinatra::JSONAPI

  helpers do
    def serialize_model(model, options = {})
      options[:is_collection] = false
      options[:skip_collection_check] = true
      super(model, options)
    end

    # Work around that allows Sinja to accept a `application/octet-steam`.
    # Sinja is opinionated and does not allow this by default.
    # See App::Middleware::SetContentHeaders for details
    def write_octet_stream(path)
      payload = env['cached.octet_stream'].read
      if payload.length.to_s == env['CONTENT_LENGTH']
        FileUtils.mkdir_p File.dirname(path)
        File.write(path, payload)
      else
        raise Sinja::BadRequestError, <<~ERROR.chomp
          Could not upload the file as the payload and content length do not match
          Recieved #{payload.length} B but expected #{env['CONTENT_LENGTH']}
        ERROR
      end
    end
  end

  FileModel.inherited_classes.each do |klass|
    filename_regex = /\A#{klass.new('(?<id>.*)').filename}\Z/

    find_from_filename = proc do |filename|
      next nil unless filename_regex.match?(filename)
      id = filename_regex.match(filename)['id']
      klass.exists?(id) ? klass.read(id) : nil
    end

    get("/authorize/download/#{klass.type}/:filename") do
      if find_from_filename.call(params[:filename])
        return 201
      else
        raise Sinja::ForbiddenError
      end
    end

    resource klass.type, pkre: /\w+/ do
      helpers do
        # The find method needs to be dynamically defined as the block preforms
        # a closure around the parent context. This way the `klass` variable is
        # available inside the block
        define_method(:find) do |id|
          klass.exists?(id) ? klass.read(id) : nil
        end
      end

      show

      index do
        klass.glob_read('*')
      end

      create do |_attr, id|
        model = find(id) || klass.create(id)
        next model.id, model
      end

      get('/:id/upload') do
        raise Sinja::BadRequestError, <<~ERROR.chomp
          This is an upload only route. Please POST the file content to this URL
        ERROR
      end

      post('/:id/upload') do
        write_octet_stream(resource.system_path)
        serialize_model(resource)
      end
    end
  end

  # Catch all reject all other authorize requests
  get('/authorize/*') do
    binding.pry
  end
end

