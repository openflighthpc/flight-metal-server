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

require 'rack/test'
require 'rspec'
require 'rspec/collection_matchers'

ENV['RACK_ENV'] = 'test'

require 'rake'
load File.expand_path('../Rakefile', __dir__)
Rake::Task[:require].invoke

require 'fakefs/spec_helpers'

require 'json'
require 'hashie'

module RSpecSinatraMixin
  include Rack::Test::Methods
  def app()
    app = App.new
    App::Middleware::SetContentHeaders.new(app)
  end
end

# If you use RSpec 1.x you should use this instead:
RSpec.configure do |c|
	# Include the Sinatra helps into the application
	c.include RSpecSinatraMixin

	# Fake the File System each test
	c.include FakeFS::SpecHelpers::All
  FakeFS::File.define_method(:flock) { |*_| }

  def admin_headers
    header 'Authorization', "Bearer #{User.new(admin: true).generate_jwt}"
  end

  def parse_last_request_body
    Hashie::Mash.new(JSON.pase(last_request.body))
  end

  def parse_last_response_body
    Hashie::Mash.new(JSON.parse(last_response.body))
  end
end
