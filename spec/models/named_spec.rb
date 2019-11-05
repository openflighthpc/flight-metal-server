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

  shared_examples 'errors if validation fails' do |request_block|
    before(:all) do
      FakeFS.clear!
      admin_headers
      ClimateControl.modify namedconf_is_valid_command: 'exit 1' do
        instance_exec(&request_block) if request_block
      end
    end

    it 'returns bad request' do
      expect(last_response).to be_bad_request
    end
  end

  describe 'POST create' do
    request = ->() do
      body = subject_api_body config_payload: 'some config payload',
                              zone_payload:   'some zone payload'
      post "/#{described_class.type}", body
    end

    it_behaves_like 'errors if validation fails', request do
      it 'does not create the zone file' do
        expect(File.exists? subject.zone_path).to be(false)
      end

      it 'does not create the config file' do
        expect(File.exists? subject.config_path).to be(false)
      end
    end

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

    [:zone_payload, :config_payload].each do |key|
      context "with admin but without the #{key} attribute" do
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

        it 'does not create the zone file' do
          expect(File.exists? subject.zone_path).to be(false)
        end

        it 'does not create the zone config' do
          expect(File.exists? subject.config_path).to be(false)
        end
      end
    end
  end

  describe 'PATCH update' do
    request = ->() do
      create_subject_and_system_files
      body = subject_api_body config_payload: 'some config payload',
                              zone_payload:   'some zone payload'
      patch subject_api_path, body
    end

    it_behaves_like 'errors if validation fails', request

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

    context 'with admin and new content' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        create_subject_and_system_files
        patch subject_api_path, subject_api_body(zone_payload: 'UPDATED', config_payload: 'UPDATED')
      end

      it 'returns ok' do
        expect(last_response).to be_ok
      end

      include_examples 'zone files exist'

      it 'updates the zone file' do
        expect(File.read subject.zone_path).to eq('UPDATED')
      end

      it 'updates the config file' do
        expect(File.read subject.config_path).to eq('UPDATED')
      end
    end
  end

  describe 'DELETE destroy' do
    request = ->() do
      create_subject_and_system_files
      delete subject_api_path
    end

    it_behaves_like 'errors if validation fails', request do
      it 'does not delete the meta file' do
        expect(File.exists? subject.path).to be(true)
      end

      it 'deos not delete the zone file' do
        expect(File.exists? subject.zone_path).to be(true)
      end

      it 'does not delete the config file' do
        expect(File.exists? subject.config_path).to be(true)
      end
    end

    context 'with admin and existing forward and reverse' do
      before(:all) do
        FakeFS.clear!
        admin_headers
        create_subject_and_system_files
        delete subject_api_path
      end

      it 'returns no content' do
        expect(last_response).to be_no_content
      end

      it 'deletes the meta file' do
        expect(File.exists? subject.path).to be(false)
      end

      it 'deletes the zone file' do
        expect(File.exists? subject.zone_path).to be(false)
      end

      it 'deletes the config file' do
        expect(File.exists? subject.config_path).to be(false)
      end
    end
  end
end

