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
    ['test_subject-tag', 'reverse']
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
      config_payload: 'content of config file',
      zone_payload: 'content of zone file'
    }
  end

  def create_subject_and_system_files
    described_class.create(*subject_inputs) do |named|
      FileUtils.mkdir_p File.dirname(named.zone_path)
      FileUtils.mkdir_p File.dirname(named.config_path)
      FileUtils.touch named.zone_path
      FileUtils.touch named.config_path
    end
  end

  shared_examples 'zone files exist' do
    it 'has the zone file' do
      expect(File.exists? subject.zone_path).to be(true)
    end

    it 'has the config file' do
      expect(File.exists? subject.config_path).to be(true)
    end
  end

  describe 'POST create' do
    context 'with admin, existing entry, and system files' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        create_subject_and_system_files
        post "/#{described_class.type}", subject_api_body(standard_attributes)
      end

      it 'returns conflict' do
        expect(last_response.status).to be(409)
      end
    end

    context 'with admin and payloads' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        body = subject_api_body config_payload: 'some config payload',
                                zone_payload:   'some zone payload'
        post "/#{described_class.type}", body
      end

      it 'returns created' do
        expect(last_response).to be_created
      end

      it 'creates the meta file' do
        expect(File.exists? subject.path).to be(true)
      end

      include_examples 'zone files exist'
    end

    [:forward_zone_name, :forward_zone_payload, :reverse_zone_name, :reverse_zone_payload].each do |key|
      context "with admin and standard attributes except the #{key}" do
        before(:all) do
          FakeFS.clear!
          admin_headers
          attr = standard_attributes.dup.tap { |a| a.delete(key) }
          post "/#{described_class.type}", subject_api_body(attr)
        end

        xit 'returns bad request' do
          expect(last_response).to be_bad_request
        end

        xit 'does not create the meta file' do
          expect(File.exists? subject.path).to be(false)
        end

        xit 'does not create the forward zone' do
          expect(File.exists? subject.forward_zone_path).to be(false)
        end

        xit 'does not create the reverse zone' do
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

      xit 'returns created' do
        expect(last_response).to be_created
      end

      xit 'creates the meta file' do
        expect(File.exists? subject.path).to be(true)
      end

      include_examples 'zone files exist'

      xit 'does not create the reverse zone' do
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

      xit 'returns not found' do
        expect(last_response).to be_not_found
      end
    end

    context 'with admin and reverse payload, but without reverse name' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        patch subject_api_path, subject_api_body(reverse_zone_payload: 'I am missing a name')
      end

      xit 'returns bad request' do
        expect(last_response).to be_bad_request
      end

      xit 'does not create the zone file' do
        expect(File.exists? subject.reverse_zone_path).to be(false)
      end
    end

    context 'with admin, without existing reverse, with reverse payload and name attributes' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        patch subject_api_path, subject_api_body(reverse_zone_name: 'this should set the name',
                                                 reverse_zone_payload: 'I am the file content')
      end

      xit 'returns ok' do
        expect(last_response).to be_ok
      end
    end

    context 'with admin, existing reverse, reverse payload attributes, without reverse name attribute' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        patch subject_api_path, subject_api_body(reverse_zone_payload: 'the name has already been set')
      end

      xit 'returns ok' do
        expect(last_response).to be_ok
      end
    end
  end

  describe 'DELETE destroy' do
    context 'with admin and existing forward and reverse' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        delete subject_api_path
      end

      xit 'returns no content' do
        expect(last_response).to be_no_content
      end

      xit 'deletes the meta file' do
        expect(File.exists? subject.path).to be(false)
      end

      xit 'deletes the forward zone' do
        expect(File.exists? subject.forward_zone_path).to be(false)
      end

      xit 'deletes the reverse zone' do
        expect(File.exists? subject.reverse_zone_path).to be(false)
      end
    end
  end
end

