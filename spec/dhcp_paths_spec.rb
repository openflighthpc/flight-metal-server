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

RSpec.describe MetalServer::DhcpIncluder do
  describe '#write_include_files' do
    def base
      DhcpBase.path
    end

    def index
      MetalServer::DhcpCurrent.new(base).index
    end

    def paths
      MetalServer::DhcpPaths.current(base)
    end

    context 'without any files' do
      before(:all) do
        FakeFS.clear!
        described_class.new(base, index).write_include_files
      end

      it 'writes an empty subnet list file' do
        expect(File.read paths.include_subnets).to be_empty
      end
    end

    context 'with multiple subnet system paths without metadata nor hosts' do
      def subnets
        ['subnet1', 'potato', 'subnet2']
      end

      before(:all) do
        FakeFS.clear!
        subnets.each do |name|
          path = DhcpSubnet.new(name).system_path
          FileUtils.mkdir_p File.dirname(path)
          FileUtils.touch path
        end
        described_class.new(base, index).write_include_files
      end

      it 'writes each subnet into the include file' do
        content = File.read(paths.include_subnets)
        expect(content).to include(*subnets)
      end

      it 'writes a empty hosts include file for each subnet' do
        subnets.each do |subnet|
          expect(File.read current_dhcp_paths.subnet_hosts(subnet)).to be_empty
        end
      end
    end

    context 'with a host file but without a subnet and without meta files' do
      it 'does not write the host include script' do
        FakeFS.clear!
        subnet  = 'subnet1'
        host    = 'host1'
        host_path = DhcpHost.new(subnet, host).system_path
        FileUtils.mkdir_p File.dirname(host_path)
        FileUtils.touch   host_path
        described_class.new(base, index).write_include_files
        expect(File.exists? current_dhcp_paths.subnet_hosts(subnet)).to be(false)
      end
    end

    context 'with a subnet and host files but no meta files' do
      def subnet
        'test-subnet'
      end

      def hosts
        ['host1', 'host2', 'host3']
      end

      before(:all) do
        FakeFS.clear!
        subnet_path = MetalServer::DhcpPaths.current(base).subnet_conf(subnet)
        FileUtils.mkdir_p File.dirname(subnet_path)
        FileUtils.touch subnet_path
        hosts.each do |host|
          host_path = MetalServer::DhcpPaths.current(base).host_conf(subnet, host)
          FileUtils.mkdir_p File.dirname(host_path)
          FileUtils.touch host_path
        end
        described_class.new(base, index).write_include_files
      end

      it 'includes the hosts in the subnet hosts list' do
        content = File.read(MetalServer::DhcpPaths.current(base).subnet_hosts(subnet))
        hosts.each do |host|
          path = MetalServer::DhcpPaths.current(base).host_conf(subnet, host)
          expect(content).to include(File.basename(path))
        end
      end
    end
  end
end

