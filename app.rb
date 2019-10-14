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

require 'metal_server/dhcp_paths'

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
    def authorize_user!
      return if [:user, :admin].include? role
      raise Sinja::ForbiddenError, <<~ERROR.squish
        You do not have permission to access this content!
      ERROR
    end

    def authorize_admin!
      return if role == :admin
      raise Sinja::ForbiddenError, <<~ERROR.squish
        You do not have permission to access this content!
      ERROR
    end

    def serialize_model(model, options = {})
      options[:is_collection] = false
      options[:skip_collection_check] = true
      super(model, options)
    end

    # Work around that allows Sinja to accept a `application/octet-steam`.
    # Sinja is opinionated and does not allow this by default.
    # See App::Middleware::SetContentHeaders for details
    def write_octet_stream(path)
      payload = env['octet-stream.in'].read
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

    def resource_or_error
      if File.exists? resource.path
        resource
      else
        raise Sinja::NotFoundError, <<~ERROR.chomp
          Could not locate DHCP subnet: #{resource.id}
        ERROR
      end
    end

    def raise_require_payload
      raise Sinja::BadRequestError, 'The payload attribute is required with this request'
    end

    private

    def token
      if bearer_match = BEARER_REGEX.match(env['HTTP_AUTHORIZATION'] || '')
        bearer_match[:token]
      elsif cookie = cookies[:Bearer]
        cookie
      else
        raise Sinja::UnauthorizedError, <<~ERROR.squish
          The HTTP Authorization Bearer Header has not been set with this request
        ERROR
      end
    end
  end

  ID_REGEX = /[\w-]+/

  [Kickstart, Legacy, Uefi].each do |klass|
    resource klass.type, pkre: ID_REGEX do
      helpers do
        # The find method needs to be dynamically defined as the block preforms
        # a closure around the parent context. This way the `klass` variable is
        # available inside the block
        define_method(:find) do |id|
          File.exists?(klass.path(id)) ? klass.read(id) : nil
        end
      end

      show

      index do
        klass.glob_read('*')
      end

      create do |attr, id|
        begin
          new_model = klass.create(id) do |model|
            if payload = attr[:payload]
              FileUtils.mkdir_p File.dirname(model.system_path)
              File.write(model.system_path, payload)
            else
              raise_require_payload
            end
          end
          [id, new_model]
        rescue FlightConfig::CreateError
          raise Sinja::ConflictError, <<~ERROR.chomp
            Can not create the '#{klass.type.singularize}' as '#{id}' already exists
          ERROR
        end
      end

      update do |attr|
        klass.update(*resource_or_error.__inputs__) do |model|
          if payload = attr[:payload]
            FileUtils.mkdir_p File.dirname(model.system_path)
            File.write model.system_path, payload.to_s
          end
        end
      end

      destroy do
        klass.delete(*resource_or_error.__inputs__) do |model|
          FileUtils.rm_f model.system_path
          true
        end
      end

      if klass == Kickstart
        get("/:id/blob") do
          env['octet-stream.out'] = File.read resource.system_path
          ''
        end
      end
    end
  end

  resource DhcpSubnet.type, pkre: ID_REGEX do
    helpers do
      def find(id)
        File.exists?(DhcpSubnet.path(id)) ? DhcpSubnet.read(id) : nil
      end
    end

    show

    index { DhcpSubnet.glob_read('*') }

    create do |attr, id|
      begin
        new_subnet = DhcpSubnet.create(id) do |subnet|
          if payload = attr[:payload]
            MetalServer::DhcpUpdater.update!(DhcpBase.path) do
              FileUtils.mkdir_p File.dirname(subnet.system_path)
              File.write(subnet.system_path, payload)
            end
          else
            raise_require_payload
          end
        end
        [id, new_subnet]
      rescue FlightConfig::CreateError
        raise Sinja::ConflictError, <<~ERROR.chomp
          Can not create the '#{DhcpSubnet.type.singularize}' as '#{id}' already exists
        ERROR
      end
    end

    update do |attr|
      DhcpSubnet.update(*resource.__inputs__) do |subnet|
        if payload = attr[:payload]
          MetalServer::DhcpUpdater.update!(DhcpBase.path) do
            FileUtils.mkdir_p File.dirname(subnet.system_path)
            File.write subnet.system_path, payload
          end
        end
      end
    end

    destroy do
      raise Sinja::ConflictError, <<~ERROR.squish if resource_or_error.read_dhcp_hosts.any?
        Can not delete the subnet whilst it still has hosts. Please delete
        the hosts and try again.
      ERROR
      DhcpSubnet.delete(*resource.__inputs__) do |subnet|
        MetalServer::DhcpUpdater.update!(DhcpBase.path) do
          FileUtils.rm_f subnet.system_path
        end
        true
      end
    end

    has_many DhcpHost.type do
      fetch do
        resource_or_error.read_dhcp_hosts
      end
    end
  end

  SimpleHostRegex = /#{ID_REGEX}\.#{ID_REGEX}/
  MatchHostRegex  = /(#{ID_REGEX})\.(#{ID_REGEX})/
  resource DhcpHost.type, pkre: SimpleHostRegex do
    helpers do
      def find(id)
        subnet, name = MatchHostRegex.match(id).captures
        if DhcpSubnet.exists?(subnet)
          File.exists?(DhcpHost.path(subnet, name)) ? DhcpHost.read(subnet, name) : nil
        else
          raise Sinja::ConflictError, <<~ERROR.squish
            Can not proceed with this request as the DHCP subnet does
            not exist. Missing subnet: #{subnet}
          ERROR
        end
      end
    end

    show
    index   { DhcpHost.glob_read('*', '*') }

    update do |attr|
      DhcpHost.update(*resource.__inputs__) do |host|
        if payload = attr[:payload]
          MetalServer::DhcpUpdater.update!(DhcpBase.path) do
            FileUtils.mkdir_p File.dirname(host.system_path)
            File.write host.system_path, payload
          end
        end
      end
    end

    destroy do
      DhcpHost.delete(*resource.__inputs__) do |host|
        MetalServer::DhcpUpdater.update!(DhcpBase.path) do
          FileUtils.rm_f host.system_path
        end
        true
      end
    end

    has_one DhcpSubnet.type do
      pluck { resource_or_error.read_dhcp_subnet }
    end
  end

  resource BootMethod.type, pkre: ID_REGEX do
    helpers do
      def find(id)
        BootMethod.read(id)
      end

      def filter(collection, fields = {})
        if fields[:complete]
          collection.select(&:complete?)
        else
          collection
        end
      end
    end

    show { resource_or_error }

    index(filter_by: [:complete])  do
      BootMethod.glob_read('*')
    end

    update do |_|
      BootMethod.create_or_update(*resource.__inputs__)
    end

    destroy do
      BootMethod.delete(*resource_or_error.__inputs__) do |boot|
        FileUtils.rm_f boot.kernel_system_path
        FileUtils.rm_f boot.initrd_system_path
        true
      end
    end

    {
      'kernel-blob' => -> (model) { model.kernel_system_path },
      'initrd-blob' => -> (model) { model.initrd_system_path }
    }.each do |blob_type, path_lambda|
      get("/:id/#{blob_type}") do
        authorize_user!
        # The response is cached in the environment as Middleware is needed to
        # Sinja enforcing JSON responses
        env['octet-stream.out'] = File.read path_lambda.call(resource_or_error)
        ''
      end

      post("/:id/#{blob_type}") do
        authorize_admin!
        write_octet_stream(path_lambda.call(resource_or_error))
        serialize_model(resource_or_error)
      end
    end
  end
end

require 'app/version'



