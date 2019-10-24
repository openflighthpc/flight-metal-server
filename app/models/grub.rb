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

class Grub < FileModel
  class << self
    def path(sub_type, name)
      File.join(content_base_path, 'meta/grub', sub_type, name + '.yaml')
    end

    def type
      'grubs'
    end
  end

  def sub_type
    __inputs__[0]
  end

  def name
    __inputs__[1]
  end

  def id
    __inputs__.join('.')
  end

  def filename
    'grub.cfg-' + name
  end

  def system_dir
    ENV["Grub_#{sub_type}_system_dir"] || raise(Sinja::NotFoundError, <<~ERROR.squish)
      Unrecognised Grub sub type '#{sub_type}'. Contact your system administrator for
      further assistance.
    ERROR
  end

  def system_path
    File.join(system_dir, filename)
  end
end

