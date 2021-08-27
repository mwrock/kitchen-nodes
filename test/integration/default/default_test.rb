# InSpec test for recipe xe_active_directory::default

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/
#require 'chef/handler'

def chef_node_attribute_data
  node_data = node.to_h
  node_data['chef_environment'] = node.chef_environment

  node_data
end

# node = json(join(ENV['TEMP'] || '/tmp', 'kitchen/nodes/node2-ubuntu-2004.json').params
node = chef_node_attribute_data

describe user('vagrant') do
  it { should exist }
end

describe json(join(ENV['TEMP'] || '/tmp', 'kitchen/nodes/node1-ubuntu-2004.json')) do
  its('id') { should eq 'node1-ubuntu-2004' }
  its(['automatic','ipaddress']) { should_not eq '127.0.0.1' }
  its(['automatic','ipaddress']) { should match(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) }
  its(['automatic','platform']) { should eq 'ubuntu' }
  its(['automatic','platform']) { should_not eq node['fqdn'] }
end
