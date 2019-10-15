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

RSpec.describe DhcpHost do
  include_context 'with_system_path_subject'

  def subnet_inputs
    ["subnet-for-subject_#{described_class.type}"]
  end

  def subject_inputs
    [
      *subnet_inputs,
      "test-subject_#{described_class.type}"
    ]
  end

  def create_subject_subnet
    DhcpSubnet.create(*subnet_inputs) do |model|
      FileUtils.mkdir_p File.dirname(model.system_path)
      FileUtils.touch model.system_path
    end
  end

  def create_subject_and_system_path
    create_subject_subnet
    DhcpHost.create(*subject_inputs) do |model|
      FileUtils.mkdir_p File.dirname(model.system_path)
      FileUtils.touch   model.system_path
    end
  end

  describe 'GET show' do
    context 'with an existing file but without a subnet' do
      context 'with user credentials' do
        before(:all) do
          FakeFS.clear!
          create_subject_and_system_path
          FileUtils.rm_f read_subject.read_dhcp_subnet.path
          user_headers
          get subject_api_path
        end

        it 'returns a conflict' do
          expect(last_response.status).to be(409)
        end
      end
    end

    context 'with user credentials, a subnet but without a meta file' do
      before(:all) do
        FakeFS.clear!
        create_subject_and_system_path
        FileUtils.rm_f read_subject.path
        user_headers
        get subject_api_path
      end

      it 'returns Not Found' do
        expect(last_response.status).to be(404)
      end
    end
  end

  include_examples 'system path creater' do
    context 'with admin credentials, payload, and subnet but when validtion fails' do
      def test_payload
        'this payload assumable caused DHCP validtion to fail'
      end

      before(:all) do
        ENV['validate_dhcpd_command'] = 'exit 1'
        FakeFS.clear!
        admin_headers
        post "/#{described_class.type}", subject_api_body(payload: test_payload)
      end

      after(:all) do
        ENV['validate_dhcpd_command'] = 'echo Reset Mock DHCPD Is Running Command'
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

  describe 'PATCH update' do
    def test_payload
      "I am the test PATCH payload for #{described_class.type}"
    end

    context 'with admin credentials and a subnet but without a payload or any hosts' do
      before(:all) do
        FakeFS.clear!
        create_subject_subnet
        admin_headers
        patch subject_api_path, subject_api_body
      end

      it 'returns not found' do
        expect(last_response).to be_not_found
      end
    end

    context 'with admin credentilas, subnet, host, but without payload' do
      def original_payload
        'I am the original host payload'
      end

      before(:all) do
        FakeFS.clear!
        create_subject_and_system_path
        File.write(read_subject.system_path, original_payload)
        admin_headers
        patch subject_api_path, subject_api_body
      end

      it 'returns okay' do
        expect(last_response).to be_ok
      end

      it 'does not update the system file' do
        expect(File.read(subject.system_path)).to eq(original_payload)
      end
    end

    context 'with admin credentials, payload, subnet, and host' do
      before(:all) do
        FakeFS.clear!
        create_subject_and_system_path
        admin_headers
        patch subject_api_path, subject_api_body(payload: test_payload)
      end

      it 'succeeds' do
        expect(last_response).to be_ok
      end

      it 'creates the meta file' do
        expect(File.exists? subject.path).to be(true)
      end

      it 'writes the payload to the system file' do
        expect(File.read subject.system_path).to eq(test_payload)
      end

      it 'includes the host in the hosts list' do
        path = current_dhcp_paths.subnet_hosts(*subnet_inputs)
        expect(File.read path).to include(subject.system_path)
      end
    end
  end

  describe 'DELETE destroy' do
    context 'with admin credentials, meta, subnet, and files' do
      before(:all) do
        FakeFS.clear!
        create_subject_and_system_path
        admin_headers
        delete subject_api_path
      end

      it 'returns No Content' do
        expect(last_response.status).to be(204)
      end

      it 'deletes the meta file' do
        expect(File.exists? subject.path).to be(false)
      end

      it 'deletes the system file' do
        expect(File.exists? subject.system_path).to be(false)
      end
    end
  end

  context 'with admin credentials, meta, subnet, and files when validation fails' do
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

    it 'does not delete the system file' do
      expect(File.exists? subject.system_path).to be(true)
    end
  end
end

