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

class Grub < SingleIDFileModel
  class << self
    def inherited(klass)
      inherited_classes << klass
    end

    def inherited_classes
      @inherited_classes ||= []
    end

    def type
      "#{sub_type}-grubs"
    end

    def system_dir_key
      "Grub_#{sub_type}_system_dir"
    end

    def system_dir
      ENV[system_dir_key]
    end

    def sub_type
      raise NotImplementedError
    end
  end

  def filename
    'grub.cfg-' + id
  end

  def system_path
    File.join(self.class.system_dir, filename)
  end
end

ENV.select { |k, _| /\AGrub_[[:alpha:]][[:alnum:]]*_system_dir\Z/.match?(k) }
   .each do |key, _|
  sub_type = /\AGrub_(?<type>.*)_system_dir\Z/.match(key).named_captures['type']
  eval <<~CLASS
    class #{sub_type.capitalize}Grub < Grub
      class << self
        def sub_type
          '#{sub_type}'
        end
      end
    end
  CLASS
end

