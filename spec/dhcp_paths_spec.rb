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

RSpec.describe MetalServer::DhcpUpdater do
  let(:base) { '/some/random/base/path' }

  describe '::modify_and_restart_dhcp!' do
    it 'errors if the config already exists' do
      FakeFS.clear!
      described_class.create(base)
      expect do
        described_class.modify_and_restart_dhcp!(base)
      end.to raise_error(FlightConfig::CreateError)
    end

    it 'deletes the config at the end of the update' do
      FakeFS.clear!
      model = described_class.modify_and_restart_dhcp!(base)
      expect(File.exists? model.path).to be(false)
    end
  end
end

