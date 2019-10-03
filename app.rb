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
require "sinatra/cookies"
require 'sinatra/jsonapi'

module Sinja
  class UnauthorizedError < HttpError
    HTTP_STATUS = 401

    def initialize(*args) super(HTTP_STATUS, *args) end
  end
end

class App < Sinatra::Base
  BEARER_REGEX = /\ABearer\s(?<token>.*)\Z/

  register Sinatra::JSONAPI
  helpers  Sinatra::Cookies

  configure_jsonapi do |c|
    # Resource roles
    c.default_roles = {
      index: [:user, :admin],
      show: [:user, :admin],
      create: :admin,
      update: :admin,
      destroy: :admin
    }

    # To-one relationship roles
    c.default_has_one_roles = {
      pluck: [:user, :admin],
      prune: :admin,
      graft: :admin
    }

    # To-many relationship roles
    c.default_has_many_roles = {
      fetch: [:user, :admin],
      clear: :admin,
      replace: :admin,
      merge: :admin,
      subtract: :admin
    }
  end

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

    def role
      User.from_jwt(token).role
    end

    private

    def token
      if bearer_match = BEARER_REGEX.match(env['HTTP_AUTHORIZATION'] || '')
        bearer_match[:token]
      elsif cookie = cookies[:bearer]
        cookie
      else
        raise Sinja::UnauthorizedError, <<~ERROR.squish
          The HTTP Authorization Bearer Header has not been set with this request
        ERROR
      end
    end
  end

  [Kickstart, Legacy, Uefi, DhcpSubnet].each do |klass|
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
    end
  end

  [KernelFile, Initrd].each do |klass|
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

      get('/:id/blob') do
        # The response is cached in the environment as Middleware is needed to
        # Sinja enforcing JSON responses
        env['cached.octet_response'] = File.read(resource.system_path)
        ''
      end

      post('/:id/blob') do
        unless role == :admin
          raise Sinja::ForbiddenError, <<~ERROR.squish
            You do not have permission to upload files. Please contact your
            system administrator for further assistance.
          ERROR
        end
        write_octet_stream(resource.system_path)
        serialize_model(resource)
      end
    end
  end
end

require 'app/version'

