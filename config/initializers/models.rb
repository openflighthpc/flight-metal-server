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

require 'flight_config'
require 'app/model'
require 'app/models/kickstart'
require 'app/models/uefi'
require 'app/models/pxelinux'
require 'app/models/kernel_file'
require 'app/models/initrd'
require 'app/models/dhcp_subnet'
require 'app/models/user'

Model.content_base_path = Figaro.env.content_base_path
FileModel.base_path = Figaro.env.default_system_dir
FileModel.base_url = Figaro.env.default_base_download_url

FileModel.inherited_classes.each do |klass|
  value = ENV["#{klass.to_s}_system_dir"]
  klass.base_path = value if value
end

DhcpSubnet.dhcp_subnet_include_path = Figaro.env.dhcp_subnet_include_config_path

User.jwt_shared_secret = Figaro.env.jwt_shared_secret

