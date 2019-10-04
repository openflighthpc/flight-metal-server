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

RSpec.describe Kickstart do
  Kickstart::TEST_SUBJECT_ID = 'foo_kickstart'

  subject { described_class.read(Kickstart::TEST_SUBJECT_ID) }

  def subject_api_path(*a)
    File.join('/', described_class.type, Kickstart::TEST_SUBJECT_ID, *a)
  end

  def create_subject_and_file
    described_class.create(Kickstart::TEST_SUBJECT_ID) do |meta|
      FileUtils.mkdir_p File.dirname(meta.system_path)
      FileUtils.touch meta.system_path
    end
  end

  describe 'get show' do
  end

  describe 'GET /kickstart/:id/blob' do
    context 'without credentials' do
      it 'errors 403' do
        unknown_headers
        get subject_api_path('blob')
        expect([401, 403]).to include(last_response.status)
      end
    end

    context 'with a file' do
      context 'with a user token' do
        before(:all) do
          FakeFS.clear!
          create_subject_and_file
          user_headers
          get subject_api_path('blob')
        end

        it 'returns ok' do
          expect(last_response).to be_ok
        end

        it 'returns the file' do
          expect(last_response.body).to eq(File.read(subject.system_path))
        end
      end
    end
  end
end

