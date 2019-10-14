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

RSpec.shared_examples 'system path creater' do
  describe 'POST create' do
    context 'with user credentials' do
      before(:all) do
        FakeFS.clear!
        user_headers
        post "/#{described_class.type}", subject_api_body(payload: 'some test payload')
      end

      it 'returns forbidden' do
        expect_forbidden
      end
    end

    context 'with admin credentials but without a payload' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        post "/#{described_class.type}", subject_api_body
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

    context 'with admin credentials and a payload but without an id' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        post "/#{described_class.type}", <<~APIJSON
          {
            "data": {
              "type": "#{described_class.type}",
              "attributes": {
                "payload": "upload without an id"
              }
            }
          }
        APIJSON
      end

      it 'returns forbidden' do
        expect_forbidden
      end
    end

    context 'with admin credentials, payload, and id' do
      def test_payload
        'I am the test payload string'
      end

      before(:all) do
        FakeFS.clear!
        admin_headers
        post "/#{described_class.type}", subject_api_body(payload: test_payload)
      end

      it 'returns created' do
        expect(last_response).to be_created
      end

      it 'creates the meta file' do
        expect(File.exists? subject.path).to be(true)
      end

      it 'writes the system file' do
        expect(File.read subject.system_path).to eq(test_payload)
      end
    end

    context 'with admin credentilas, payload, id, and existing meta' do
      def test_payload
        'I am the test payload string'
      end

      before(:all) do
        FakeFS.clear!
        admin_headers
        create_subject_and_system_path
        post "/#{described_class.type}", subject_api_body(payload: test_payload)
      end

      it 'returns a conflict' do
        expect(last_response.status).to be(409)
      end

      it 'leaves the meta file in place' do
        expect(File.exists? subject.path).to be(true)
      end

      it 'does not update the system file' do
        expect(File.read subject.system_path).to be_empty
      end
    end
  end

end

