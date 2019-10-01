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

class FileModelSerializer < Serializer
  attributes :size, :system_path, :download_url
  attribute(:uploaded) { |s| s.object.uploaded? }
end

class KickstartSerializer < FileModelSerializer; end
class KernelFileSerializer < FileModelSerializer; end
class PxelinuxSerializer < FileModelSerializer; end
class UefiSerializer < FileModelSerializer; end
class InitrdSerializer < FileModelSerializer; end
class DhcpSubnetSerializer < FileModelSerializer; end

