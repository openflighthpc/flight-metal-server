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

    def payload_update(attr)
      if payload = attr[:payload]
        resource.class.create_or_update(*resource.__inputs__) do |model|
          FileUtils.mkdir_p File.dirname(model.system_path)
          File.write model.system_path, payload.to_s
        end
      else
        raise Sinja::BadRequestError, 'The payload attribute is required with this request'
      end
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
          klass.read(id)
        end
      end

      show do
        File.exists?(resource.path) ? resource : nil
      end

      index do
        klass.glob_read('*')
      end

      update { |a| payload_update(a) }

      # Additional model based routes
      if klass == DhcpSubnet
        has_many DhcpHost.type do
          fetch do
            resource.read_dhcp_hosts
          end
        end
      end
    end
  end

  SimpleHostRegex = /\w+\/\w+/
  MatchHostRegex  = /(\w+)\/(\w+)/
  resource DhcpHost.type, pkre: SimpleHostRegex do
    helpers do
      def find(id)
        subnet, name = MatchHostRegex.match(id).captures
        if DhcpSubnet.exists?(subnet)
          DhcpHost.read(subnet, name)
        else
          raise Sinja::ForbiddenError, <<~ERROR.squish
            Can not proceed with this request as the DHCP subnet does
            not exist
          ERROR
        end
      end
    end

    show

    index do
      DhcpHost.glob_read('*', '*')
    end

    update { |a| payload_update(a) }

    has_one DhcpSubnet.type do
      pluck do
        resource.read_dhcp_subnet
      end
    end
  end

  resource BootMethod.type, pkre: /\w+/ do
    helpers do
      def find(id)
        BootMethod.exists?(id) ? BootMethod.read(id) : nil
      end

      def filter(collection, fields = {})
        if fields[:complete]
          collection.select(&:complete?)
        else
          collection
        end
      end
    end

    show

    index(filter_by: [:complete])  do
      BootMethod.glob_read('*')
    end

    create do |_attr, id|
      model = find(id) || BootMethod.create(id)
      next model.id, model
    end

    {
      'kernel_blob' => -> (model) { model.kernel_system_path },
      'initrd_blob' => -> (model) { model.initrd_system_path }
    }.each do |blob_type, path_lambda|
      get("/:id/#{blob_type}") do
        # The response is cached in the environment as Middleware is needed to
        # Sinja enforcing JSON responses
        env['cached.octet_response'] = File.read path_lambda.call(resource)
        ''
      end

      post("/:id/#{blob_type}") do
        unless role == :admin
          raise Sinja::ForbiddenError, <<~ERROR.squish
            You do not have permission to upload files. Please contact your
            system administrator for further assistance.
          ERROR
        end
        write_octet_stream(path_lambda.call(resource))
        serialize_model(resource)
      end
    end
  end
end

require 'app/version'

