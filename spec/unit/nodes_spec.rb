require "fakefs/safe"
require "kitchen"
require "kitchen/provisioner/nodes"

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
    :platform => platform
  ) }
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
end