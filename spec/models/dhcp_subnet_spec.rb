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
require 'shared_examples/system_path_creater'

RSpec.describe DhcpSubnet do
  include_context 'with_system_path_subject'

  include_examples 'system path creater' do
    context 'with admin credentails, with meta or file, and when validation errors' do
      before(:all) do
        ENV['validate_dhcpd_command'] = 'exit 1'
        FakeFS.clear!
        admin_headers
        post "/#{described_class.type}", subject_api_body(payload: 'some garbage payload')
      end

      after(:all) do
        ENV['validate_dhcpd_command'] = 'echo Reset Mock DHCPD Validate on Create Command'
      end

      it 'returns bad request' do
        expect(last_response.status).to be(400)
      end

      it 'does not create the meta file' do
        expect(File.exists? subject.path).to be(false)
      end

      it 'does not create the system file' do
        expect(File.exists? subject.system_path).to be(false)
      end
    end
  end

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

  describe 'PATCH update' do
    def test_payload
      'I am the test payload'
    end

    context 'with user crendentials, with the meta file' do
      before(:all) do
        FakeFS.clear!
        user_headers
        create_subject_and_system_path
        patch subject_api_path
      end

      it 'returns Forbidden' do
        expect(last_response.status).to be(403)
      end
    end

    context 'with admin crendentials, without any dhcp files' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        patch subject_api_path, subject_api_body
      end

      it 'returns Not Found' do
        expect(last_response).to be_not_found
      end
    end

    context 'with admin credentials, dhcp files, but without a payload' do
      def original_payload
        'I am the orignal dhcp payload'
      end

      before(:all) do
        FakeFS.clear!
        admin_headers
        create_subject_and_system_path
        File.write(read_subject.system_path, original_payload)
        patch subject_api_path, subject_api_body
      end

      it 'returns okay' do
        expect(last_response).to be_ok
      end

      it 'does not modify the stored payload' do
        expect(File.read(subject.system_path)).to eq(original_payload)
      end
    end

    context 'with admin credentials, payload, and dhcp files' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        create_subject_and_system_path
        patch subject_api_path, subject_api_body(payload: test_payload)
      end

      it 'succeeds' do
        expect(last_response).to be_ok
      end

      it 'writes the payload to the system file' do
        expect(File.read subject.system_path).to eq(test_payload)
      end

      it 'appears in the main subnet include file' do
        expect(File.read current_dhcp_paths.include_subnets).to include(subject.filename)
      end
    end

    context 'with admin credentials, payload, and dhcp files when validation fails' do
      before(:all) do
        ENV['validate_dhcpd_command'] = 'exit 1'
        FakeFS.clear!
        admin_headers
        create_subject_and_system_path
        patch subject_api_path, subject_api_body(payload: test_payload)
      end

      after(:all) do
        ENV['validate_dhcpd_command'] = 'echo Reset Mock DHCPD Is Running Command'
      end

      it 'returns Bad Request' do
        expect(last_response.status).to be(400)
      end

      it 'does not update the system file' do
        expect(File.read subject.system_path).to be_empty
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

    context 'with admin credentials, meta, but without host files' do
      before(:all) do
        FakeFS.clear!
        create_subject_and_system_path
        admin_headers
        delete subject_api_path
      end

      it 'returns No Content' do
        expect(last_response.status).to be(204)
      end

      it 'removes the meta file' do
        expect(File.exists? subject.path).to be(false)
      end

      it 'removes the system file' do
        expect(File.exists? subject.system_path).to be(false)
      end

      it 'does not appear in the subnet include list' do
        expect(File.read current_dhcp_paths.include_subnets).not_to include(subject.filename)
      end
    end

    context 'with admin credentials, meta, but without host files, when validation fails' do
      before(:all) do
        ENV['validate_dhcpd_command'] = 'exit 1'
        FakeFS.clear!
        create_subject_and_system_path
        admin_headers
        delete subject_api_path
      end

      after(:all) do
        ENV['validate_dhcpd_command'] = 'echo Reset Mock DHCPD Is Running Command'
      end

      it 'returns Bad Request' do
        expect(last_response.status).to be(400)
      end

      it 'does not delete the meta file' do
        expect(File.exists? subject.path).to be(true)
      end

      it 'does not delete the system path' do
        expect(File.exists? subject.system_path).to be(true)
      end
    end
  end
end

