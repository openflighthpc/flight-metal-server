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
  subject { read_subject }

  def read_subject
    described_class.read(*subject_inputs)
  end

  def subject_inputs
    ["test-subjet_#{described_class.type}"]
  end

  def create_subject_forward_and_reverse
    described_class.create(*subject_inputs) do |named|
      named.forward_zone_name = 'forward-zone-name'
      named.reverse_zone_name = 'reverse-zone-name'
      FileUtils.mkdir_p File.dirname(named.forward_zone_path)
      FileUtils.touch named.forward_zone_path
      FileUtils.touch named.reverse_zone_path
    end
  end

  def create_subject_and_forward
    described_class.create(*subject_inputs) do |named|
      named.forward_zone_name = 'forward-zone-name'
      FileUtils.mkdir_p File.dirname(named.forward_zone_path)
      FileUtils.touch named.forward_zone_path
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

  shared_examples 'forward zone exists' do
    it 'has the forward zone file' do
      expect(File.exists? subject.forward_zone_path).to be(true)
    end

    it 'has the forward zone name' do
      expect(subject.forward_zone_name).not_to be_empty
    end
  end

  shared_examples 'reverse zone exists' do
    it 'has the reverse zone file' do
      expect(File.exists? subject.reverse_zone_path).to be(true)
    end

    it 'has the reverse zone name' do
      expect(subject.reverse_zone_name).not_to be_empty
    end
  end

  describe 'POST create' do
    context 'with admin, exiting entry, and system files' do
      before(:all) do
        FakeFS.clear!
        create_subject_forward_and_reverse
        admin_headers
        post "/#{described_class.type}", subject_api_body(standard_attributes)
      end

      it 'returns conflict' do
        expect(last_response.status).to be(409)
      end
    end

    context 'with admin and standard attributes' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        post "/#{described_class.type}", subject_api_body(standard_attributes)
      end

      it 'returns created' do
        expect(last_response).to be_created
      end

      it 'creates the meta file' do
        expect(File.exists? subject.path).to be(true)
      end

      include_examples 'forward zone exists'
      include_examples 'reverse zone exists'
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

        it 'does not create the meta file' do
          expect(File.exists? subject.path).to be(false)
        end

        it 'does not create the forward zone' do
          expect(File.exists? subject.forward_zone_path).to be(false)
        end

        it 'does not create the reverse zone' do
          expect(File.exists? subject.reverse_zone_path).to be(false)
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

      it 'creates the meta file' do
        expect(File.exists? subject.path).to be(true)
      end

      include_examples 'forward zone exists'

      it 'does not create the reverse zone' do
        expect(File.exists? subject.reverse_zone_path).to be(false)
      end
    end
  end

  describe 'PATCH update' do
    context 'without an existing entry' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        patch subject_api_path, subject_api_body
      end

      it 'returns not found' do
        expect(last_response).to be_not_found
      end
    end

    context 'with admin and reverse payload, but without reverse name' do
      before(:all) do
        FakeFS.clear!
        create_subject_and_forward
        admin_headers
        patch subject_api_path, subject_api_body(reverse_zone_payload: 'I am missing a name')
      end

      it 'returns bad request' do
        expect(last_response).to be_bad_request
      end

      it 'does not create the zone file' do
        expect(File.exists? subject.reverse_zone_path).to be(false)
      end
    end

    context 'with admin, without existing reverse, with reverse payload and name attributes' do
      before(:all) do
        FakeFS.clear!
        create_subject_and_forward
        admin_headers
        patch subject_api_path, subject_api_body(reverse_zone_name: 'this should set the name',
                                                 reverse_zone_payload: 'I am the file content')
      end

      it 'returns ok' do
        expect(last_response).to be_ok
      end

      include_examples 'reverse zone exists'
    end

    context 'with admin, existing reverse, reverse payload attributes, without reverse name attribute' do
      before(:all) do
        FakeFS.clear!
        create_subject_forward_and_reverse
        admin_headers
        patch subject_api_path, subject_api_body(reverse_zone_payload: 'the name has already been set')
      end

      it 'returns ok' do
        expect(last_response).to be_ok
      end

      include_examples 'reverse zone exists'
    end
  end
end

