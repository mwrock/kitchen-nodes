require "fakefs/safe"
require "kitchen"
require "kitchen/provisioner/nodes"
require "kitchen/transport/dummy"

describe Kitchen::Provisioner::Nodes do

  let(:config) { { 
    :test_base_path => "/b",
    :kitchen_root => "/r",
    :run_list => "cookbook:recipe" 
  } }
  let(:instance) { double(
    "instance",
    :name => "test_suite",
    :suite => suite,
    :platform => platform,
    :transport => dummy_transport
  ) }
  let(:dummy_transport) { Kitchen::Transport::Dummy.new }
  let(:platform) { double("platform", :os_type => nil) }
  let(:suite) { double("suite", :name => "suite") }
  let(:state) { { :hostname => "192.168.1.10" } }
  let(:node) { JSON.parse(File.read(subject.node_file), :symbolize_names => true) }

  before {
    FakeFS.activate!
    FileUtils.mkdir_p(config[:test_base_path])
    allow_any_instance_of(Kitchen::StateFile).to receive(:read).and_return(state)
  }
  after {
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  }

  subject { Kitchen::Provisioner::Nodes.new(config).finalize_config!(instance) }

  it "creates node" do
    subject.create_node

    expect(File).to exist(subject.node_file)
  end

  it "sets the id" do
    subject.create_node

    expect(node[:id]).to eq instance.name
  end

  it "sets the runlist" do
    subject.create_node

    expect(node[:run_list]).to eq config[:run_list]
  end

  it "sets the ip address" do
    subject.create_node

    expect(node[:automatic][:ipaddress]).to eq state[:hostname]
  end

  context "instance is localhost" do
    let(:state) { { :hostname => "127.0.0.1" } }
    let(:machine_ips) { [ "192.168.1.1", "192.168.1.2", "192.168.1.3" ] }
    
    before {
      allow_any_instance_of(Net::Ping::External).to receive(:ping).and_return(true)
    }
    context "platform is windows" do
      let(:dummy_transport) { double("winrm", :connection => dummy_winrm_connection) }
      let(:dummy_winrm_connection) { double("connection", :node_session => dummy_executor) }
      let(:dummy_executor) { double("executor") }

      before {
        allow(dummy_executor).to receive(:run_powershell_script) do |&block|
          machine_ips.each do |ip|
            block.call(ip)
          end
        end
      }

      it "sets the ip address to the first reachable IP" do
        subject.create_node

        expect(node[:automatic][:ipaddress]).to eq machine_ips.first
      end

      context "only the last ip is reachable" do
        before {
          allow_any_instance_of(Net::Ping::External).to receive(:ping).and_return(false)
          allow_any_instance_of(Net::Ping::External).to receive(:ping).with(machine_ips.last).and_return(true)
        }

        it "sets the ip address to the last IP" do
          subject.create_node

          expect(node[:automatic][:ipaddress]).to eq machine_ips.last
        end
      end
    end
  end
end