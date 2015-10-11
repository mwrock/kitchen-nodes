first_node = search_for_nodes(
  "run_list:*node1* AND platform:#{node['platform']}")

ruby_block 'Save first attributes' do
  block do
    parent = File.join(ENV['TEMP'] || '/tmp', 'kitchen')
    IO.write(File.join(parent, 'other_node.json'), first_node[0].to_json)
  end
end
