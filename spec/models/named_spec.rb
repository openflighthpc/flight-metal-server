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

RSpec.describe Named do
  def subject_inputs
    ["test-subjet_#{described_class.type}"]
  end

  def create_subject_and_system_files
    described_class.create(*subject_inputs) do |named|
      named.forward_zone_name = 'forward-zone-name'
      named.reverse_zone_name = 'reverse-zone-name'
      FileUtils.mkdir_p File.dirname(named.forward_zone_path)
      FileUtils.touch named.forward_zone_path
      FileUtils.touch named.reverse_zone_path
    end
  end

  def subject_api_path(*a)
    File.join('/', described_class.type, subject_inputs.join('.'), *a)
  end

  def subject_api_body(**attributes)
    attributes_string = attributes.map do |key, value|
      "\"#{key}\": \"#{value}\""
    end.join(",\n")

    <<~APIJSON
      {
        "data": {
          "type": "#{described_class.type}",
          "id": "#{subject_inputs.join('.')}",
          "attributes": {
            #{ attributes_string }
          }
        }
      }
    APIJSON
  end

  def standard_attributes
    {
      forward_zone_name: 'name-of-the-forward-zone',
      reverse_zone_name: 'name-of-the-reverse-zone',
      forward_zone_payload: 'content in the forward zone',
      reverse_zone_payload: 'content in the reverse zone'
    }
  end

  describe 'POST create' do
    context 'with admin, exiting entry, and system files' do
      before(:all) do
        FakeFS.clear!
        create_subject_and_system_files
        admin_headers
        post "/#{described_class.type}", subject_api_body(standard_attributes)
      end

      it 'returns conflict' do
        expect(last_response.status).to be(409)
      end
    end

    [:forward_zone_name, :forward_zone_payload, :reverse_zone_name, :reverse_zone_payload].each do |key|
      context "with admin and standard attributes except the #{key}" do
        before(:all) do
          FakeFS.clear!
          admin_headers
          attr = standard_attributes.dup.tap { |a| a.delete(key) }
          post "/#{described_class.type}", subject_api_body(attr)
        end

        it 'returns bad request' do
          expect(last_response).to be_bad_request
        end
      end
    end

    context 'with admin and standard attributes except the reverse zone keys' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        attr = standard_attributes.reject { |k, _| /reverse/.match?(k) }
        post "/#{described_class.type}", subject_api_body(attr)
      end

      it 'returns created' do
        expect(last_response).to be_created
      end
    end
  end
end

