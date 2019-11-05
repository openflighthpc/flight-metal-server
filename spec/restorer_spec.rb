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

RSpec.describe MetalServer::Restorer do
  let(:base) { '/some/random/base/path' }

  let(:test_error) { Interrupt }

  def raise_test_error
    raise test_error
  end

  describe '::backup_and_restore_on_error' do
    it 'errors if the config already exists' do
      FakeFS.clear!
      described_class.create(base)
      expect do
        described_class.backup_and_restore_on_error(base)
      end.to raise_error(FlightConfig::CreateError)
    end

    it 'deletes the config at the end of the update' do
      FakeFS.clear!
      model = described_class.backup_and_restore_on_error(base)
      expect(File.exists? model.path).to be(false)
    end

    it 'deletes the config even if their was an error' do
      FakeFS.clear!
      begin
        described_class.modify_and_restart_dhcp(base) { raise 'Some Error' }
      rescue
        # noop
      end
      expect(File.exists? described_class.path(base)).to be(false)
    end

    context 'with existing dhcp files' do
      let(:test_content)      { 'original test dhcp content' }
      let(:new_test_content)  { 'new test content' }

      let(:subnets) do
        ['subnet1', 'subnetA']
      end

      let(:hosts) do
        [
          ['subnet1', 'host1'], ['subnet1', 'host2'],
          ['subnetA', 'hostA'], ['subnet2', 'hostB']
        ]
      end

      let(:paths) do
        cur_paths = MetalServer::DhcpPaths.current(base)
        [
          *subnets.map { |s| cur_paths.subnet_conf(s) },
          *hosts.map { |s, h| cur_paths.host_conf(s, h) }
        ]
      end

      # Creates all the files
      before do
        FakeFS.clear!
        paths.each do |path|
          FileUtils.mkdir_p File.dirname(path)
          File.write path, test_content
        end
      end

      it 'leaves the new file content on success' do
        described_class.backup_and_restore_on_error(base) do
          paths.each { |p| File.write(p, new_test_content) }
        end
        paths.each do |path|
          expect(File.read path).to eq(new_test_content)
        end
      end

      it 'restores the old file content on error' do
        expect do
          described_class.backup_and_restore_on_error(base) do
            paths.each { |p| File.write(p, new_test_content) }
            raise test_error
          end
        end.to raise_error(test_error)
        paths.each do |path|
          expect(File.read path).to eq(test_content)
        end
      end
    end
  end
end

