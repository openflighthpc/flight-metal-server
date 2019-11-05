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
  def self.type
    'nameds'
  end

  def self.zone_dir
    File.join(Figaro.env.Named_working_dir, Figaro.env.Named_sub_dir)
  end

  def self.config_dir
    config_join
  end

  def self.config_join(*a)
    File.join(Figaro.env.Named_config_dir, Figaro.env.Named_sub_dir, *a)
  end

  # NOTE: The subnets file should have a different extension to all the zone
  # configs. This is to prevent them being mixed up in a glob
  def self.subnets_path
    config_join('subnets.config')
  end

  def self.path(*a)
    File.join(content_base_path, 'meta', type, id(*a) + '.yaml')
  end

  def self.id(tag, zone_class)
    "#{tag}.#{zone_class}"
  end

  def update_payloads(zone_payload: nil, config_payload: nil, **_)
    if zone_payload
      FileUtils.mkdir_p File.dirname(zone_path)
      File.write zone_path, zone_payload
    end
    if config_payload
      FileUtils.mkdir_p File.dirname(config_path)
      File.write config_path, config_payload
    end
  end

  def tag
    __inputs__[0]
  end

  def zone_class
    __inputs__[1]
  end

  def id
    self.class.id(*__inputs__)
  end

  def zone_path
    File.join(self.class.zone_dir, id)
  end

  def zone_uploaded?
    File.exists? zone_path
  end

  def zone_uploaded
    zone_uploaded?
  end

  def zone_size
    return 0 unless zone_uploaded?
    File.size zone_path
  end

  def zone_payload
    return '' unless zone_uploaded?
    File.read(zone_path)
  end

  def config_path
    File.join(self.class.config_dir, id + '.conf')
  end

  def config_uploaded?
    File.exists? config_path
  end

  def config_uploaded
    config_uploaded?
  end

  def config_size
    return 0 unless config_uploaded?
    File.size config_path
  end

  def config_payload
    return '' unless config_uploaded?
    File.read(config_path)
  end
end

