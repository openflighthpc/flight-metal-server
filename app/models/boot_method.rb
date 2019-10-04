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

class BootMethod < SingleIDFileModel
  def self.type
    'boot-methods'
  end

  def kernel_filename
    "#{id}.kernel"
  end

  def initrd_filename
    "#{id}.initrd"
  end

  def kernel_system_path
    File.join(Figaro.env.Kernel_system_dir, kernel_filename)
  end

  def initrd_system_path
    File.join(Figaro.env.Initrd_system_dir, initrd_filename)
  end

  {
    'kernel' => ->(model) { model.kernel_system_path },
    'initrd' => ->(model) { model.initrd_system_path }
  }.map { |k, p| [k, p, ->(m) { File.exists? p.call(m) }] }
   .each do |type, path_lambda, exists_lambda|
    define_method("#{type}_uploaded?") do
      exists_lambda.call(self)
    end

    # Defined to make it easy to serialize
    define_method("#{type}_uploaded") do
      exists_lambda.call(self)
    end

    define_method("#{type}_size") do
      return 0 unless exists_lambda.call(self)
      File.size path_lambda.call(self)
    end
  end
end

