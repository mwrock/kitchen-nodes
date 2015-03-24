# <a name="title"></a> Kitchen::Nodes

A Test Kitchen Provisioner that generates searchable Nodes.

## <a name="installation"></a> Installation and Setup

Please read the [Driver usage][driver_usage] page for more details.

## <a name="config"></a> Configuration

```
provisioner:
  name: nodes
```

The nodes provisioner extends the `chef-zero` provisioner along with all of its functionality and configuration.

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


[author]:           https://github.com/enter-github-user
[issues]:           https://github.com/enter-github-user/kitchen-nodes/issues
[license]:          https://github.com/enter-github-user/kitchen-nodes/blob/master/LICENSE
[repo]:             https://github.com/enter-github-user/kitchen-nodes
[driver_usage]:     http://docs.kitchen-ci.org/drivers/usage
[chef_omnibus_dl]:  http://www.getchef.com/chef/install/
