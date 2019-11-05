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

require 'app/models/grub'

class Service
  TYPE_MAP = {
    :'boot-methods' => (Figaro.env.enable_netboot == 'true'),
    :'dhcp-subnets' => (Figaro.env.enable_dhcp == 'true'),
    :'dhcp-hosts'   => (Figaro.env.enable_dhcp == 'true'),
    :grubs          => (Figaro.env.enable_netboot == 'true'),
    :kickstarts     => (Figaro.env.enable_kickstart == 'true'),
    :legacies       => (Figaro.env.enable_netboot == 'true'),
    :nameds         => true
  }.freeze

  def self.pkre
    /#{TYPE_MAP.keys.join('|')}/
  end

  def self.type
    'services'
  end

  def self.all
    TYPE_MAP.keys.map { |i| new(i) }
  end

  def self.enabled?(id)
    TYPE_MAP[id.to_sym]
  end

  def self.ids
    TYPE_MAP.keys
  end

  attr_reader :id

  def initialize(id)
    if TYPE_MAP.key?(id.to_sym)
      @id = id.to_sym
    else
      raise Sinja::NotFoundError, <<~ERROR.squish
        Could not locate the service: #{id}
      ERROR
    end
  end

  def enabled?
    TYPE_MAP[id]
  end

  def enabled
    enabled?
  end
end

