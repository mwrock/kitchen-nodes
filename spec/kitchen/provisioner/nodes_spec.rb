require 'logger'
require 'stringio' unless defined?(StringIO)

require 'kitchen/configurable'
require 'kitchen'
require 'kitchen/logging'
require 'kitchen/provisioner/nodes'
require 'kitchen/driver/dummy'
require 'kitchen/transport/dummy'
require 'kitchen/transport/winrm'
require 'kitchen/transport/ssh'
require 'kitchen/verifier/dummy'
require 'fakefs/safe'
require 'winrm'
require 'erb'

describe Kitchen::Provisioner::Nodes do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform)        { double('platform', os_type: nil, name: 'ubuntu') }
  let(:suite)           { double('suite', name: 'suite') }
  let(:verifier)        { Kitchen::Verifier::Dummy.new }
  let(:driver)          { Kitchen::Driver::Dummy.new }
  let(:transport)       { Kitchen::Transport::Ssh.new }
  let(:state_file)      { { hostname: '192.168.1.10' } }
  let(:node) { JSON.parse(File.read(provisioner.node_file), symbolize_names: false) }

  let(:config) do
    {
      test_base_path: '/b',
      kitchen_root: '/r',
      run_list: ['recipe[cookbook::default]'],
      attributes: { 'att_key' => 'att_val' },
      client_rb: { environment: 'my_env' },
      named_run_list: 'testing',
      policy_group: 'test',
      reset_node_files: false,
    }
  end

  let(:instance) do
    double(
      'instance',
      name: 'test_suite',
      logger: logger,
      suite: suite,
      platform: platform,
      transport: transport,
      driver: driver
    )
  end

  let(:provisioner) do
    Kitchen::Provisioner::Nodes.new(config).finalize_config!(instance)
  end

  before do
    FakeFS.activate!
    FileUtils.mkdir_p(config[:test_base_path])
    allow_any_instance_of(Kitchen::StateFile).to receive(:read).and_return(state_file)
    allow(transport).to receive(:connection).and_return(Kitchen::Transport::Base::Connection.new)
    allow_any_instance_of(Kitchen::Transport::Base::Connection).to receive(:node_execute).with('hostname -f').and_return("fakehostname\n\n")
  end
  after do
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  it 'creates node' do
    provisioner.create_node
  end

  describe '#create_node' do
    context 'node file does not exist' do
      before do
        allow(Dir).to receive(:exist?).and_return(false)
      end

      it 'creates node' do
        provisioner.create_node
        expect(File).to exist(provisioner.node_file)
      end
    end

    context 'node file exists' do
      before do
        allow(Dir).to receive(:exist?).and_return(true)
        expect(File).to receive(:exist?).twice.with(provisioner.node_file).and_return(true)
      end

      context 'config[:reset_node_files] = false' do
        it 'does not update the node file' do
          expect(File).not_to receive(:open)
          expect(File).to exist(provisioner.node_file)
          provisioner.create_node
        end
      end

      context 'config[:reset_node_files] = true' do
        before do
          config[:reset_node_files] = true
        end

        it 'updates the node file' do
          expect(File).to receive(:open)
          expect(File).to exist(provisioner.node_file)
          provisioner.create_node
        end
      end
    end
  end

  it 'sets the id' do
    provisioner.create_node
    expect(node['id']).to eq instance.name
  end

  it 'sets the environment' do
    provisioner.create_node
    expect(node['chef_environment']).to eq config[:client_rb][:environment]
  end

  it 'sets the runlist' do
    provisioner.create_node
    expect(node['run_list']).to eq config[:run_list]
  end

  it 'expands the runlist' do
    provisioner.create_node
    expect(node['automatic']['recipes']).to eq ['cookbook::default']
  end

  it 'sets the normal attributes' do
    provisioner.create_node
    expect(node['normal']).to eq config[:attributes]
  end

  it 'sets the ip address' do
    provisioner.create_node
    expect(node['automatic']['ipaddress']).to eq state_file[:hostname]
  end

  it 'sets the fqdn' do
    provisioner.create_node
    expect(node['automatic']['fqdn']).to eq 'fakehostname'
  end

  context 'cannot obtain fqdn' do
    before do
      allow_any_instance_of(Kitchen::Transport::Base::Connection).to receive(:node_execute).with('hostname -f').and_raise(Kitchen::Transport::TransportFailed.new(''))
    end

    it 'sets the fqdn to nil' do
      provisioner.create_node
      expect(node['automatic']['fqdn']).to be_nil
    end
  end

  context 'no environment explicitly set' do
    before { config.delete(:client_rb) }

    it 'sets the environment' do
      provisioner.create_node
      expect(node['chef_environment']).to eq '_default'
    end
  end

  context 'instance is localhost' do
    let(:state_file) { { hostname: '127.0.0.1' } }
    let(:machine_ips) { ['192.168.1.1', '192.168.1.2', '192.168.1.3'] }

    before do
      allow_any_instance_of(Net::Ping::External).to receive(:ping).and_return(true)
    end

    context 'cannot find an ip' do
      let(:ifconfig_response) do
        FakeFS.deactivate!
        template = File.read('spec/kitchen/provisioner/stubs/ifconfig.txt')
        FakeFS.activate!
        template.gsub!('', machine_ips[0])
        template.gsub!('', machine_ips[1])
        template.gsub!('', machine_ips[2])
      end
      let(:transport) { Kitchen::Transport::Ssh.new }

      before do
        allow_any_instance_of(Kitchen::Transport::Base::Connection).to receive(:node_execute).and_return(ifconfig_response)
      end

      it 'fails' do
        expect { provisioner.create_node }.to raise_error('Unable to retrieve IPs')
      end
    end

    context 'platform is windows' do
      let(:transport) { Kitchen::Transport::Winrm.new }

      before do
        data = WinRM::Output.new
        data << { stdout: "\r\n" }
        machine_ips.map { |ip| data << { stdout: "IPv4 Address .: #{ip}\r\n" } }
        allow_any_instance_of(Kitchen::Transport::Base::Connection).to(receive(:node_execute).and_return(data))
        allow(platform).to receive(:name).and_return('windows')
      end

      it 'sets the ip address to the first reachable IP' do
        provisioner.create_node
        expect(node['automatic']['ipaddress']).to eq machine_ips.first
      end

      context 'only the last ip is reachable' do
        before do
          allow_any_instance_of(Net::Ping::TCP).to receive(:ping).and_return(false)
          allow_any_instance_of(Net::Ping::External).to receive(:ping).and_return(false)
          allow_any_instance_of(Net::Ping::External).to receive(:ping).with(machine_ips.last).and_return(true)
        end

        it 'sets the ip address to the last IP' do
          provisioner.create_node
          expect(node['automatic']['ipaddress']).to eq machine_ips.last
        end
      end
    end

    context 'platform is *nix' do
      let(:ifconfig_response) do
        FakeFS.deactivate!
        template = File.read('spec/kitchen/provisioner/stubs/ifconfig.txt')
        FakeFS.activate!
        template.gsub!('1.1.1.1', machine_ips[0])
        template.gsub!('2.2.2.2', machine_ips[1])
        template.gsub!('3.3.3.3', machine_ips[2])
      end
      let(:transport) { Kitchen::Transport::Ssh.new }

      before do
        allow_any_instance_of(Kitchen::Transport::Base::Connection).to receive(:node_execute).and_return(ifconfig_response)
      end

      it 'sets the ip address to the RUNNING IP that is not localhost' do
        provisioner.create_node
        expect(node['automatic']['ipaddress']).to eq machine_ips[1]
      end

      context 'ifconfig not supported' do
        let(:ip_response) do
          FakeFS.deactivate!
          template = File.read('spec/kitchen/provisioner/stubs/ip.txt')
          FakeFS.activate!
          template.gsub!('1.1.1.1', machine_ips[0])
          template.gsub!('2.2.2.2', machine_ips[1])
          template.gsub!('3.3.3.3', machine_ips[2])
        end

        before do
          allow_any_instance_of(Kitchen::Transport::Base::Connection).to receive(:node_execute).with('/sbin/ifconfig -a').and_raise(Kitchen::Transport::TransportFailed.new(''))
          allow_any_instance_of(Kitchen::Transport::Base::Connection).to receive(:node_execute).with('/sbin/ip -4 addr show').and_return(ip_response)
        end

        it 'sets the ip address to the connected IP that is not localhost' do
          provisioner.create_node
          expect(node['automatic']['ipaddress']).to eq machine_ips[0]
        end
      end
    end
  end
end
