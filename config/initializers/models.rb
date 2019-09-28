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
require 'app/models/initrd_kernel'

Model.content_base_path = Figaro.env.content_base_path
DownloadableFileModel.base_storage_path = Figaro.env.base_storage_path
DownloadableFileModel.base_download_url = Figaro.env.base_download_url

Pxelinux.base_system_path      = Figaro.env.pxelinux_base_system_path
Uefi.base_system_path          = Figaro.env.uefi_base_system_path

InitrdKernel.base_path  = Figaro.env.initrd_kernel_base_path
InitrdKernel.base_url   = Figaro.env.initrd_kernel_base_url

