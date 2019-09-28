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

class Model
  include FlightConfig::Reader
  include FlightConfig::Updater
  include FlightConfig::Globber

  class << self
    attr_writer :content_base_path

    def content_base_path
      Model.instance_variable_get(:@content_base_path) || raise(<<~ERROR.chomp)
        The base content path for the models has not been set!
      ERROR
    end

    def exists?(*a)
      File.exists? path(*a)
    end
  end

  def id
    raise NotImplementedError
  end
end

class FileModel < Model
  class << self
    attr_writer :base_path

    # NOTE: Deprecated, the file path are being standardized
    def base_path
      @base_path || raise("The #{self} base path has not been set")
    end
  end

  def system_path
    raise NotImplementedError
  end

  # alias and alias_method are not being used as they do not play
  # well with inheritance. Also I can never remember the difference
  # between the two
  def name
    id
  end

  def uploaded?
    File.exists?(system_path)
  end

  def size
    return 0 unless uploaded?
    File.size system_path
  end
end

# TODO: Eventually make this a complete replacement to FileModel
# All files need to follow this same pattern. However it will be
# phased-in in stages
class DownloadableFileModel < Model
  class << self
    attr_writer :base_storage_path, :base_download_url

    def base_storage_path
      DownloadableFileModel.instance_variable_get(:@base_storage_path) || raise(<<~ERROR.chomp)
        The base storage path for the models has not been set
      ERROR
    end

    def base_download_url
      DownloadableFileModel.instance_variable_get(:@base_download_url) || raise(<<~ERROR.chomp)
        The base download url has not been set
      ERROR
    end

    # This is used by the serializer to define the type
    def type
      raise NotImplementedError
    end
  end

  # The name of the object is equivalent to its ID
  def name
    id
  end

  def filename
    raise NotImplementedError
  end

  def storage_path
    File.join(self.class.base_storage_path, self.class.type, filename)
  end

  def download_url
    File.join(self.class.base_download_url, self.class.type, filename)
  end

  def uploaded?
    File.exists? storage_path
  end

  def size
    return 0 unless uploaded?
    File.size storage_path
  end
end

module SystemFile
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_writer :base_system_path

    def base_system_path
      @base_system_path || raise(<<~ERROR.chomp)
        The base system path for #{self.class} has not been set
      ERROR
    end
  end

  def system_path
    raise NotImplementedError
  end
end

