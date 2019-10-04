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

require 'spec_helper.rb'

RSpec.describe BootMethod do
  TEST_SUBJECT_ID = 'foo-test-boot-method'
  subject { described_class.read(TEST_SUBJECT_ID) }

  def join_path(*a)
    a ||= []
    File.join("/#{described_class.type}", *a)
  end

  let(:id) do
    'foo'
  end

  describe '#list' do
    context 'with admin credentials' do
      def make_request
        admin_headers
        get join_path
      end

      context 'without any models' do
        it 'passes' do
          make_request
          expect(last_response).to be_ok
        end

        it 'returns an empty list' do
          make_request
          expect(parse_last_response_body.data).to be_empty
        end
      end

      context 'with a meta, kernel, and initrd' do
        # Only creates the subject and request once
        before(:all) do
          described_class.create(TEST_SUBJECT_ID) do |boot|
            [boot.kernel_system_path, boot.initrd_system_path].each do |path|
              FileUtils.mkdir_p File.dirname(path)
              FileUtils.touch path
            end
          end
          make_request
        end

        it 'returns one entry' do
          expect(parse_last_response_body.data).to have_exactly(1).item
        end

        it 'has the correct type' do
          expect(parse_last_response_body.data.first.type).to eq(described_class.type)
        end

        it 'is complete' do
          expect(parse_last_response_body.data.first.attributes.complete).to eq(true)
        end
      end
    end
	end
end
