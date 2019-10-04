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

RSpec.describe DhcpHost do
  include_context 'with_system_path_subject'

  def subject_inputs
    [
      "subnet_for_subject_#{described_class.type.gsub('-', '_')}",
      "subject_#{described_class.type.gsub('-', '_')}"
    ]
  end

  def create_subject_and_system_path
    DhcpSubnet.create(subject_inputs.first)
    DhcpHost.create(*subject_inputs) do |model|
      FileUtils.mkdir_p File.dirname(model.system_path)
      FileUtils.touch   model.system_path
    end
  end

  it_behaves_like 'system path deleter'

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
  end
end

