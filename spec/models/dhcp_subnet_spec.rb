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

RSpec.describe DhcpSubnet do
  include_context 'single_input_test_subject'

  describe 'DELETE destroy' do
    def make_request(*a)
      delete subject_api_path(*a)
    end

    context 'with an existing config' do
      include_examples 'error_without_credenitals'

      context 'with admin credentials' do
        before(:all) do
          FakeFS.clear!
          create_subject_and_system_path
          admin_headers
          make_request
        end

        it 'returns no content' do
          expect(last_response).to be_no_content
        end

        it 'removes the meta file' do
          expect(File.exists? subject.path).to be false
        end

        it 'removes the system file' do
          expect(File.exists? subject.system_path).to be false
        end
      end

      context 'with user credentials' do
        before(:all) do
          FakeFS.clear!
          create_subject_and_system_path
          user_headers
          make_request
        end

        it 'is forbidden' do
          expect_forbidden
        end

        it 'it does not delete the record' do
          expect(File.exists? subject.path).to be true
          expect(File.exists? subject.system_path).to be true
        end
      end
    end
  end
end

