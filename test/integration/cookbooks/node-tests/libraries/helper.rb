require 'timeout'

def search_for_nodes(query, timeout = 120)
  nodes = []
  Timeout::timeout(timeout) do
    nodes = search(:node, query)
    until  nodes.count > 0 && nodes[0].has_key?('ipaddress')
      sleep 5
      nodes = search(:node, query)
    end
  end

  if nodes.count == 0 || !nodes[0].has_key?('ipaddress')
    raise "Unable to find any nodes meeting the search criteria '#{query}'!"
  end

  nodes
end
