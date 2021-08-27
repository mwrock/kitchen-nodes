# InSpec test for recipe xe_active_directory::default

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/

node = JSON.parse(File.read(join(ENV['TEMP'] || '/tmp', 'kitchen/nodes/node2-ubuntu-2004.json')), symbolize_names: false)

describe user('vagrant') do
  it { should exist }
end

describe json(join(ENV['TEMP'] || '/tmp', 'kitchen/nodes/node1-ubuntu-2004.json')) do
  its('id') { should eq 'node1-ubuntu-2004' }
  its(%w(automatic ipaddress)) { should_not eq '127.0.0.1' }
  its(%w(automatic ipaddress)) { should match(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) }
  its(%w(automatic platform)) { should eq 'ubuntu' }
  its(%w(automatic platform)) { should_not eq node['fqdn'] }
end
