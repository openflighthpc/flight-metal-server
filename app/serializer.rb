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

class Serializer
  include JSONAPI::Serializer

  class << self
    attr_writer :base_url

    def base_url
      @base_url || raise('The serializer base url has not been set')
    end
  end

  def base_url
    Serializer.base_url
  end

  def type
    object.class.type
  end
end

module SerializePayload
  extend ActiveSupport::Concern

  included do
    attribute :payload
  end
end

class BootMethodSerializer < Serializer
  has_one :kernel_blob
  has_one :initrd_blob

  attributes :complete

  [
    'system_path', 'size', 'uploaded'
  ].each do |attr|
    attributes :"kernel_#{attr}", :"initrd_#{attr}"
  end
end

class FileModelSerializer < Serializer
  attributes :size, :system_path, :filename
  attribute(:uploaded) { |s| s.object.uploaded? }
end

class KickstartSerializer < FileModelSerializer
  include SerializePayload

  has_one :blob
end

class LegacySerializer < FileModelSerializer
  include SerializePayload
end

class GrubSerializer < FileModelSerializer
  include SerializePayload

  attributes :sub_type, :name
end

class DhcpSubnetSerializer < FileModelSerializer
  include SerializePayload

  has_many :dhcp_hosts

  attribute :hosts_path
end

class DhcpHostSerializer < FileModelSerializer
  include SerializePayload

  has_one :dhcp_subnet
end

class ServiceSerializer < Serializer
  attributes :enabled
end

