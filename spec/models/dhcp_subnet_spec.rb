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

require 'spec_helper'
require 'shared_examples/system_path_deleter'

RSpec.describe DhcpSubnet do
  include_context 'with_system_path_subject'

  describe 'GET show' do
    context 'with user crendentials, without the meta file' do
      before(:all) do
        FakeFS.clear!
        user_headers
        get subject_api_path
      end

      it 'returns Not Found' do
        expect(last_response.status).to be(404)
      end
    end
  end

  describe 'GET fetch dhcp-hosts' do
    context 'with user crendentials, without the meta file' do
      before(:all) do
        FakeFS.clear!
        user_headers
        get subject_api_path('dhcp-hosts')
      end

      it 'returns Not Found' do
        expect(last_response.status).to be(404)
      end
    end
  end

  describe 'DELETE destroy' do
    context 'with admin credentials, meta, and a host files' do
      before(:all) do
        FakeFS.clear!
        create_subject_and_system_path
        DhcpHost.create(*subject_inputs, 'foo-host')
        admin_headers
        delete subject_api_path
      end

      it 'returns a conflict' do
        expect(last_response.status).to be(409)
      end
    end
  end
end

