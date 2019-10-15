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

RSpec.describe BootMethod do
  TEST_SUBJECT_ID = "test-subject_#{described_class.type}"
  subject { read_subject }

  def read_subject
    described_class.read(TEST_SUBJECT_ID)
  end

  def join_path(*a)
    a ||= []
    File.join('/', described_class.type, *a)
  end

  def subject_api_path(*a)
    join_path(TEST_SUBJECT_ID, *a)
  end

  let(:id) do
    'foo'
  end

  def create_subject_kernel_and_initrd
    described_class.create(TEST_SUBJECT_ID) do |boot|
      [boot.kernel_system_path, boot.initrd_system_path].each do |path|
        FileUtils.mkdir_p File.dirname(path)
        FileUtils.touch path
      end
    end
  end

  describe 'GET index' do
    context 'with admin credentials' do
      def make_request(*a)
        admin_headers
        get join_path, *a
      end

      context 'without any models' do
        before(:all) do
          FakeFS.clear!
        end

        it 'passes' do
          make_request
          expect(last_response).to be_ok
        end

        it 'returns an empty list' do
          make_request
          expect(parse_last_response_body.data).to be_empty
        end
      end

      context 'with a meta, kernel, and initrd files' do
        # Only creates the subject and request once
        before(:all) do
          FakeFS.clear!
          create_subject_kernel_and_initrd
          make_request
        end

        it 'returns one entry' do
          expect(parse_last_response_body.data).to have_exactly(1).item
        end

        it 'has the correct type' do
          expect(parse_last_response_body.data.first.type).to eq(described_class.type)
        end

        it 'has the correct id' do
          expect(parse_last_response_body.data.first.id).to eq(subject.id)
        end

        it 'is complete' do
          expect(parse_last_response_body.data.first.attributes.complete).to eq(true)
        end
      end

      ['kernel', 'initrd'].each do |type|
        context "with only the meta and #{type} files" do
          # Only creates the subject and request once
          before(:all) do
            FakeFS.clear!
            described_class.create(TEST_SUBJECT_ID) do |boot|
              path = boot.send("#{type}_system_path")
              FileUtils.mkdir_p File.dirname(path)
              FileUtils.touch path
            end
          end

          context 'without any query parameters' do
            before(:all) { make_request }

            it 'is included with the request' do
              expect(parse_last_response_body.data.first.id).to eq(subject.id)
            end
          end

          context 'with complete query parameter' do
            before(:all) { make_request('', { 'QUERY_STRING' => 'filter[complete]=true' }) }

            it 'does not get indexed' do
              expect(parse_last_response_body.data).to be_empty
            end
          end
        end
      end
    end
	end

  describe 'DELETE destroy' do
    context 'with admin credentials' do
      def make_request
        admin_headers
        get    subject_api_path
        raise 'Failed to get subject' unless last_response.ok?
        delete subject_api_path, parse_last_response_body.data.to_s
      end

      context 'with the meta, kenerl, and initrd files' do
        before(:all) do
          FakeFS.clear!
          create_subject_kernel_and_initrd
          make_request
        end

        it 'removes the meta file' do
          expect(File.exists? subject.path).to be false
        end

        it 'removes the kenerl file' do
          expect(File.exists? subject.kernel_system_path).to be false
        end

        it 'removes the initrd file' do
          expect(File.exists? subject.initrd_system_path).to be false
        end
      end
    end
  end

  ['kernel', 'initrd'].each do |type|
    describe "GET /#{BootMethod.type}/:id/#{type}-blob" do
      define_method(:read_subject_test_blob) do
        path = if type == 'kernel'
          read_subject.kernel_system_path
        elsif type == 'initrd'
          read_subject.initrd_system_path
        else
          raise 'Unexpected Error'
        end
        File.read path
      end

      define_method(:make_request) do
        get subject_api_path("#{type}-blob")
      end

      context 'with meta and system files' do
        context 'with user credentials' do
          before(:all) do
            FakeFS.clear!
            create_subject_kernel_and_initrd
            user_headers
            make_request
          end

          it 'passes' do
            expect(last_response).to be_ok
          end

          it 'returns the file' do
            expect(last_response.body).to eq(read_subject_test_blob)
          end
        end
      end

      context 'without authorization credentials' do
        include_examples 'error_without_credentials'
      end
    end

    describe "POST /#{BootMethod.type}/:id/#{type}-blob" do
      define_method(:read_subject_test_blob) do
        path = if type == 'kernel'
          read_subject.kernel_system_path
        elsif type == 'initrd'
          read_subject.initrd_system_path
        else
          raise 'Unexpected Error'
        end
        File.read path
      end

      def new_post_content
        'I am the new post content string'
      end

      define_method(:make_request) do
        post( subject_api_path("#{type}-blob"),
              new_post_content,
              {
                'Content-Length' => new_post_content.length.to_s,
                'CONTENT_TYPE'   => 'application/octet-stream'
              })
      end

      context 'with meta and system files' do
        context 'with user credentials' do
          before(:all) do
            FakeFS.clear!
            create_subject_kernel_and_initrd
            user_headers
            make_request
          end

          it 'is forbidden' do
            expect(last_response.status).to be(403)
          end
        end

        context 'with admin credentials' do
          before(:all) do
            FakeFS.clear!
            create_subject_kernel_and_initrd
            admin_headers
            make_request
          end

          it 'passes' do
            expect(last_response).to be_ok
          end

          it 'updates the files content' do
            expect(read_subject_test_blob).to eq(new_post_content)
          end
        end
      end

      context 'without authorization credentials' do
        include_examples 'error_without_credentials'
      end
    end
  end
end
