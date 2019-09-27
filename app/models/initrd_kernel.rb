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

class InitrdKernel < Model
  class << self
    attr_writer :base_path, :base_url

    def path(id)
      File.join(content_base_path, 'initrd-kernel', id + '.yaml')
    end

    def base_path
      @base_path || raise("The #{self} base path has not been set")
    end

    def base_url
      @base_url || raise('The initrdkernerl base url has not been set')
    end
  end

  def id
    __inputs__[0]
  end

  def name
    id
  end

  def kernel_system_path
    File.join(self.base_path, id + '.kernel')
  end

  def initrd_system_path
    File.join(self.base_path, id + '.initrd')
  end

  def kernel_uploaded?
    File.exists? kernel_system_path
  end

  def initrd_uploaded?
    File.exists? initrd_system_path
  end

  def kernel_size
    return 0 unless kernel_uploaded?
    File.size kernel_system_path
  end

  def initrd_size
    return 0 unless initrd_uploaded?
    File.size initrd_system_path
  end
end
