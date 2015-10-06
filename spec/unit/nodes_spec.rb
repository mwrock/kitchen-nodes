require 'erb'
require 'fakefs/safe'
require 'kitchen'
require 'kitchen/driver/dummy'
require 'kitchen/provisioner/nodes'
require 'kitchen/transport/dummy'
require 'kitchen/transport/winrm'
require 'kitchen/transport/ssh'

describe Kitchen::Provisioner::Nodes do
  let(:config) do
    {
      test_base_path: '/b',
      kitchen_root: '/r',
      run_list: 'cookbook:recipe',
      attributes: { att_key: 'att_val' },
      client_rb: { environment: 'my_env' }
    }
  end
  let(:instance) do
    double(
      'instance',
      name: 'test_suite',
      suite: suite,
      platform: platform,
      transport: transport,
      driver: Kitchen::Driver::Dummy.new
    )
  end
  let(:transport) { Kitchen::Transport::Dummy.new }
  let(:platform) { double('platform', os_type: nil, name: 'ubuntu') }
  let(:suite) { double('suite', name: 'suite') }
  let(:state) { { hostname: '192.168.1.10' } }
  let(:node) { JSON.parse(File.read(subject.node_file), symbolize_names: true) }

  before do
    FakeFS.activate!
    FileUtils.mkdir_p(config[:test_base_path])
    allow_any_instance_of(Kitchen::StateFile)
      .to receive(:read).and_return(state)
  end
  after do
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  subject { Kitchen::Provisioner::Nodes.new(config).finalize_config!(instance) }

  it 'creates node' do
    subject.create_node

    expect(File).to exist(subject.node_file)
  end

  it 'sets the id' do
    subject.create_node

    expect(node[:id]).to eq instance.name
  end

  it 'sets the environment' do
    subject.create_node

    expect(node[:chef_environment]).to eq config[:client_rb][:environment]
  end

  it 'sets the runlist' do
    subject.create_node

    expect(node[:run_list]).to eq config[:run_list]
  end

  it 'sets the normal attributes' do
    subject.create_node

    expect(node[:normal]).to eq config[:attributes]
  end

  it 'sets the ip address' do
    subject.create_node

    expect(node[:automatic][:ipaddress]).to eq state[:hostname]
  end

  context 'cannot obtain fqdn' do
    before do
      allow_any_instance_of(Kitchen::Transport::Base::Connection)
        .to receive(:node_execute).with('hostname -f')
        .and_raise(Kitchen::Transport::TransportFailed.new(''))
    end

    it 'sets the fqdn to nil' do
      subject.create_node
      expect(node[:automatic][:fqdn]).to be_nil
    end
  end

  context 'can obtain fqdn' do
    before do
      allow_any_instance_of(Kitchen::Transport::Base::Connection)
        .to receive(:node_execute).with('hostname -f')
        .and_return('fakehostname')
    end

    it 'sets the fqdn' do
      subject.create_node
      expect(node[:automatic][:fqdn]).to eq 'fakehostname'
    end
  end

  context 'no environment explicitly set' do
    before { config.delete(:client_rb) }

    it 'sets the environment' do
      subject.create_node

      expect(node[:chef_environment]).to eq '_default'
    end
  end

  context 'instance is localhost' do
    let(:state) { { hostname: '127.0.0.1' } }
    let(:machine_ips) { ['192.168.1.1', '192.168.1.2', '192.168.1.3'] }

    before do
      allow_any_instance_of(Net::Ping::External).to receive(:ping)
        .and_return(true)
      allow(transport).to receive(:connection)
        .and_return(Kitchen::Transport::Base::Connection.new)
    end

    context 'cannot find an ip' do
      let(:ifconfig_response) do
        FakeFS.deactivate!
        template = File.read('spec/unit/stubs/ifconfig.txt')
        FakeFS.activate!
        template.gsub!('', machine_ips[0])
        template.gsub!('', machine_ips[1])
        template.gsub!('', machine_ips[2])
      end
      let(:transport) { Kitchen::Transport::Ssh.new }

      before do
        allow_any_instance_of(Kitchen::Transport::Base::Connection)
          .to receive(:node_execute).and_return(ifconfig_response)
      end

      it 'fails' do
        expect { subject.create_node }.to raise_error('Unable to retrieve IPs')
      end
    end

    context 'platform is windows' do
      let(:transport) { Kitchen::Transport::Winrm.new }

      before do
        data = machine_ips.map { |ip| { stdout: "#{ip}\r\n" } }
        allow_any_instance_of(Kitchen::Transport::Base::Connection).to(
          receive(:node_execute).and_return(data: data)
        )
        allow(platform).to receive(:name).and_return('windows')
      end

      it 'sets the ip address to the first reachable IP' do
        subject.create_node

        expect(node[:automatic][:ipaddress]).to eq machine_ips.first
      end

      context 'only the last ip is reachable' do
        before do
          allow_any_instance_of(Net::Ping::External).to receive(:ping)
            .and_return(false)
          allow_any_instance_of(Net::Ping::External).to receive(:ping)
            .with(machine_ips.last).and_return(true)
        end

        it 'sets the ip address to the last IP' do
          subject.create_node

          expect(node[:automatic][:ipaddress]).to eq machine_ips.last
        end
      end
    end

    context 'platform is *nix' do
      let(:ifconfig_response) do
        FakeFS.deactivate!
        template = File.read('spec/unit/stubs/ifconfig.txt')
        FakeFS.activate!
        template.gsub!('1.1.1.1', machine_ips[0])
        template.gsub!('2.2.2.2', machine_ips[1])
        template.gsub!('3.3.3.3', machine_ips[2])
      end
      let(:transport) { Kitchen::Transport::Ssh.new }

      before do
        allow_any_instance_of(Kitchen::Transport::Base::Connection)
          .to receive(:node_execute).and_return(ifconfig_response)
      end

      it 'sets the ip address to the RUNNING IP that is not localhost' do
        subject.create_node

        expect(node[:automatic][:ipaddress]).to eq machine_ips[1]
      end

      context 'ifconfig not supported' do
        let(:ip_response) do
          FakeFS.deactivate!
          template = File.read('spec/unit/stubs/ip.txt')
          FakeFS.activate!
          template.gsub!('1.1.1.1', machine_ips[0])
          template.gsub!('2.2.2.2', machine_ips[1])
          template.gsub!('3.3.3.3', machine_ips[2])
        end

        before do
          allow_any_instance_of(Kitchen::Transport::Base::Connection)
            .to receive(:node_execute).with('/sbin/ifconfig -a')
            .and_raise(Kitchen::Transport::TransportFailed.new(''))

          allow_any_instance_of(Kitchen::Transport::Base::Connection)
            .to receive(:node_execute).with('/sbin/ip -4 addr show')
            .and_return(ip_response)
        end

        it 'sets the ip address to the connected IP that is not localhost' do
          subject.create_node

          expect(node[:automatic][:ipaddress]).to eq machine_ips[0]
        end
      end
    end
  end
end
