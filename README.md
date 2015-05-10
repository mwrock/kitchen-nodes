# <a name="title"></a> Kitchen::Nodes

A Test Kitchen Provisioner that generates searchable Nodes.

The nodes provisioner extends the `chef-zero` provisioner along with all of its functionality and configuration. `chef-zero` can support chef searches by querying against node data stored in json files inside of the kitchen `nodes` folder. The `kitchen-nodes` plugin automatically generates a node file when a test instance is provisioned by test-kitchen.

### Example nodes:

```
{
  "id": "server-community-ubuntu-1204",
  "automatic": {
    "ipaddress": "172.17.0.8",
    "platform": "ubuntu"
  },
  "normal": {
    "attr1": "val1"
  }
  "run_list": [
    "recipe[apt]",
    "recipe[couchbase-tests::ipaddress]",
    "recipe[couchbase::server]",
    "recipe[export-node]"
  ]
}

{
  "id": "second-node-ubuntu-1204",
  "automatic": {
    "ipaddress": "172.17.0.9",
    "platform": "ubuntu"
  },
  "run_list": [
    "recipe[apt]",
    "recipe[couchbase-tests::ipaddress]",
    "recipe[couchbase-tests::default]",
    "recipe[export-node]"
  ]
}
```

The node data includes the node id based on the test-kitchen suite name, the run list assigned to the node, the normal attributes included in the `.kitchen.yml` file, the externally reachable ip address and the platform of the test instance os.

## <a name="installation"></a> Installation

```
gem install kitchen-nodes
```

## <a name="config"></a> Configuration

Use `nodes` instead of `chef-zero` for the kitchen provisioner name.

```
provisioner:
  name: nodes
```

## <a name="Usage"></a> Usage

Using `kitchen-nodes` one can expect all previously converged nodes to be represented in a node file and be searchable. For example consider this scenario looking for a primary node in a cluster in order to add a node to join:

```
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
    raise "Unable to find nodes!"
  end

  nodes
end

primary = search_for_nodes("run_list:*couchbase??server* AND platform:#{node['platform']}")
node.normal["couchbase-tests"]["primary_ip"] = primary[0]['ipaddress']

```
### <a name="vagrant"></a> Using with Vagrant

When using kitchen-nodes with the vagrant driver, make sure you add the following to your `driver_config`:

```
network:
  - ["private_network", { type: "dhcp" }]
```

This will add an additional non-NAT NIC to your vagrant box with an IP reachable from the host and other test nodes.

### <a name="virtualbox"></a> Why is my ohai `ipaddress` different from my node ipaddress on vagrant with VirtualBox?

Ohai will pick up the localhost ipaddress on vagrant boxes using virtualbox. To reset the `node["ipaddress"]` to the reachable ip, add `hurry-up-and-test::set_non_nat_vbox_ip` to the top of your `run_list`. 

```
suites:
  - name: my-suite
    run_list:
      - recipe[hurry-up-and-test::set_non_nat_vbox_ip]
      - recipe[cookbook-under-test]
```

You can add this even if you do not use virtualbox and the recipe will do nothing.


## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## <a name="authors"></a> Authors

Created and maintained by [Matt Wrock][author] (<matt@mattwrock.com>)

## <a name="license"></a> License

Apache 2.0 (see [LICENSE][license])


[author]:           https://github.com/mwrock
[issues]:           https://github.com/mwrock/kitchen-nodes/issues
[license]:          https://github.com/mwrock/kitchen-nodes/blob/master/LICENSE
[repo]:             https://github.com/mwrock/kitchen-nodes
[driver_usage]:     http://docs.kitchen-ci.org/drivers/usage
[chef_omnibus_dl]:  http://www.getchef.com/chef/install/
