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

RSpec.describe MetalServer::DhcpPaths do
  subject { described_class.new(base, version) }

  let(:base)    { '/some/random/base/path' }
  let(:version) { 10 }

  describe '#master_include' do
    let(:subject_path) { subject.master_include }

    it 'is not defined with the version' do
      expect(subject_path).not_to include(version.to_s)
    end
  end

  describe '#include_subnets' do
    let(:subject_path) { subject.include_subnets }

    it 'is defined with the version' do
      expect(subject_path).to include(version.to_s)
    end
  end

  context 'with a named subnet' do
    let(:subnet_name)     { 'test-subnet' }
    let(:conf_dir)        { File.dirname(subject.subnet_conf(subnet_name)) }
    let(:hosts_conf_dir)  { File.dirname(subject.subnet_hosts(subnet_name)) }

    it 'defines its config and hosts list in the same directory' do
      expect(conf_dir).to eq(hosts_conf_dir)
    end

    context 'with a named host' do
      let(:host_name)     { 'test-host' }
      let(:host_conf_dir) { File.dirname(subject.host_conf(subnet_name, host_name)) }

      it 'defines a config one directory down from its subnet' do
        expect(host_conf_dir).to eq(File.join(conf_dir, "#{subnet_name}.hosts"))
      end
    end
  end
end

RSpec.describe MetalServer::DhcpCurrent do
  let(:base)        { '/path/to/base/dhcp/configs' }
  let(:random_max)  { 100 }
  let(:random_ids)  { (0..10).map { rand(random_max) }.uniq }

  let(:max_id)      { random_max + 10 }
  let(:test_ids)    { [*random_ids, max_id, 'strings-should-be-ignored'].shuffle }

  subject { described_class.new(base) }

  context 'with all the test ids' do
    before do
      FakeFS.clear!
      test_ids.each do |id|
        path = MetalServer::DhcpPaths.new(base, id).include_subnets
        FileUtils.mkdir_p File.dirname(path)
        FileUtils.touch   path
      end
    end

    describe '#id' do
      it 'returns the maximum id' do
        expect(subject.id).to be(max_id)
      end
    end
  end

  context 'without any ids' do
    before do
      FakeFS.clear!
    end

    describe '#id' do
      it 'returns 0' do
        expect(subject.id).to be(0)
      end
    end
  end
end

RSpec.describe MetalServer::DhcpRestorer do
  let(:base) { '/some/random/base/path' }

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
      let(:old_id) { 5 }

      let(:test_content) { 'test dhcp content' }

      let(:subnets) do
        ['subnet1', 'subnetA']
      end

      let(:hosts) do
        [
          ['subnet1', 'host1'], ['subnet1', 'host2'],
          ['subnetA', 'hostA'], ['subnet2', 'hostB']
        ]
      end

      let(:old_paths) do
        cur_paths = MetalServer::DhcpPaths.new(base, old_id)
        [
          cur_paths.include_subnets,
          *subnets.map { |s| cur_paths.subnet_conf(s) },
          *subnets.map { |s| cur_paths.subnet_hosts(s) },
          *hosts.map { |s, h| cur_paths.host_conf(s, h) }
        ]
      end

      let(:new_paths) do
        old_paths.map { |path| path.sub(old_id.to_s, (old_id + 1).to_s) }
      end

      let(:test_error) { Interrupt }

      def raise_test_error
        raise test_error
      end

      # Creates all the files
      before do
        FakeFS.clear!
        old_paths.each do |path|  FileUtils.mkdir_p File.dirname(path)
          File.write path, test_content
        end
      end

      it 'copies the old entries to the new direcotry before yielding' do
        old_file_content = old_paths.map { |p| File.read p }
        described_class.backup_and_restore_on_error(base) do
          new_paths.each_with_index do |path, idx|
            expect(File.exists? path).to be(true)
            expect(File.read path).to eq(old_file_content[idx])
          end
        end
      end

      it 'leaves the new files in place if success' do
        described_class.backup_and_restore_on_error(base)
        new_paths.each { |p| expect(File.exists? p).to be(true) }
      end

      it 'deletes the old paths if success' do
        described_class.backup_and_restore_on_error(base)
        expect(Dir.exists? MetalServer::DhcpPaths.new(base, old_id).join).to be(false)
      end

      it 'leaves the old files on error' do
        expect do
          described_class.backup_and_restore_on_error(base) { raise_test_error }
        end.to raise_error(test_error)
        old_paths.each { |p| expect(File.exists? p).to be(true) }
      end

      it 'deletes the new files on error' do
        expect do
          described_class.backup_and_restore_on_error(base) { raise_test_error }
        end.to raise_error(test_error)
        expect(Dir.exists? MetalServer::DhcpPaths.new(base, old_id + 1).join).to be(false)
      end

      it 'deletes the tmp files on success' do
        described_class.backup_and_restore_on_error(base)
        tmp_glob = MetalServer::DhcpPaths.new(base, "#{old_id}--*").join('**/*.conf')
        expect(Dir.glob(tmp_glob)).to be_empty
      end

      # NOTE: Periodically check if this test still work. It looks like it could
      # fail silently at any-moment
      it 'deletes the tmp files on error' do
        expect do
          described_class.backup_and_restore_on_error(base) { raise_test_error }
        end.to raise_error(test_error)
        tmp_glob = MetalServer::DhcpPaths.new(base, "#{old_id}--*").join('**/*.conf')
        expect(Dir.glob(tmp_glob)).to be_empty
      end
    end
  end
end

