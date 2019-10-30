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

class Named < Model
  include HasSingleInput

  ZONE_PROXY_REGEX = [
    :zone, :zone_path, 'zone_uploaded\?', :zone_uploaded, :zone_size
  ].map { |z| /\A(?<zone>.*)_(?<method>#{z})\Z/ }

  def self.type
    'nameds'
  end

  def self.zone_dir
    File.join(Figaro.env.Named_working_dir, Figaro.env.Named_sub_dir)
  end

  # Dummy reflective method for use in the proxy
  def zone(zone)
    zone
  end

  def zone_path(zone)
    File.join(self.class.zone_dir, "#{id}.#{zone}")
  end

  def zone_uploaded?(zone)
    File.exists? zone_path(zone)
  end

  def zone_uploaded(*a)
    zone_uploaded?(*a)
  end

  def zone_size(zone)
    return 0 unless zone_uploaded?(zone)
    File.size zone_path(zone)
  end

  def method_missing(s, *_a, &_b)
    if regex = zone_proxy_regex(s)
      matches = regex.match(s).named_captures
      inputs = ['method', 'zone'].map { |s| matches[s] }
      public_send(*inputs)
    else
      super
    end
  end

  def respond_to_missing?(s, **_h)
    zone_proxy_regex(s) ? true : super
  end

  def zone_proxy_regex(s)
    str = s.to_s
    ZONE_PROXY_REGEX.find { |r| r.match?(str) }
  end
end

