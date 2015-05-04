require "fakefs/safe"
require "kitchen"
require "kitchen/driver/dummy"
require "kitchen/provisioner/nodes"
require "kitchen/transport/dummy"
require "kitchen/transport/winrm"
require "kitchen/transport/ssh"

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
    :transport => transport,
    :driver => Kitchen::Driver::Dummy.new
  ) }
  let(:transport) { Kitchen::Transport::Dummy.new }
  let(:platform) { double("platform", :os_type => nil, :name => 'ubuntu') }
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
      allow(transport).to receive(:connection).and_return(Kitchen::Transport::Base::Connection.new)
    }
    context "platform is windows" do
      let(:transport) { Kitchen::Transport::Winrm.new }

      before {
        data = machine_ips.map {|ip| { :stdout => "#{ip}\r\n" }}
        allow_any_instance_of(Kitchen::Transport::Base::Connection).to(
          receive(:node_execute).and_return({ :data => data })
        )
        allow(platform).to receive(:name).and_return('windows')
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

    context "platform is *nix" do
      let(:transport) { Kitchen::Transport::Ssh.new }

      before {
        allow_any_instance_of(Kitchen::Transport::Base::Connection).to receive(:node_execute) do
          <<-EOS
docker0   Link encap:Ethernet  HWaddr 56:84:7a:fe:97:99  
          inet addr:#{machine_ips[0]}  Bcast:0.0.0.0  Mask:255.255.0.0
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

eth0      Link encap:Ethernet  HWaddr 08:00:27:88:0c:a6  
          inet addr:#{machine_ips[1]}  Bcast:10.0.2.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe88:ca6/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:10262 errors:0 dropped:0 overruns:0 frame:0
          TX packets:7470 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:1497781 (1.4 MB)  TX bytes:1701791 (1.7 MB)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

          EOS
        end
      }

      it "sets the ip address to the RUNNING IP that is not localhost" do
        subject.create_node

        expect(node[:automatic][:ipaddress]).to eq machine_ips[1]
      end

      context "ifconfig not supported" do
        before {
          allow_any_instance_of(Kitchen::Transport::Base::Connection)
          .to receive(:node_execute).with("ifconfig -a")
          .and_raise(Kitchen::Transport::TransportFailed.new(""))

          allow_any_instance_of(Kitchen::Transport::Base::Connection)
          .to receive(:node_execute).with("ip -4 addr show") do
            <<-EOS
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    inet #{machine_ips[0]}/24 brd 192.168.1.255 scope global wlan0
       valid_lft forever preferred_lft forever
5: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    inet #{machine_ips[1]}/16 scope global docker0
       valid_lft forever preferred_lft forever
            EOS
          end
        }

        it "sets the ip address to the connected IP that is not localhost" do
          subject.create_node

          expect(node[:automatic][:ipaddress]).to eq machine_ips[0]
        end
      end
    end
  end
end