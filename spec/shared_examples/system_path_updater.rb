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

RSpec.shared_examples 'system path updater' do
  describe 'PATCH update' do
    context 'with user credentials' do
      before(:all) do
        FakeFS.clear!
        user_headers
        create_subject_and_system_path
        patch subject_api_path, subject_api_body
      end

      it 'returns forbidden' do
        expect_forbidden
      end
    end

    context 'with admin credentials without an entry' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        patch subject_api_path, subject_api_body(payload: 'some test payload')
      end

      it 'returns not found' do
        expect(last_response).to be_not_found
      end

      it 'does not create the meta file' do
        expect(File.exists? subject.path).to be(false)
      end

      it 'does not create the system file' do
        expect(File.exists? subject.system_path).to be(false)
      end
    end

    context 'with admin credentials and entry but without a payload' do
      def original_payload
        'I am the original file content'
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

      it 'does not modify the system file' do
        expect(File.read subject.system_path).to eq(original_payload)
      end
    end
  end
end
