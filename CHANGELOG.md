# Change Log

## [0.10.0](https://github.com/mwrock/kitchen-nodes/tree/0.10.0) (2021-08-26)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.9.1...0.10.0)

**Merged pull requests:**

- merge scalp42 changes
  - added reset_node_files option, default is false, determines if nodes file should be updated or left unchanged between kitchen runs
- add name_run_list and policy_group to template
- removed version constraints to work with latest versions of dependencies [\#33](https://github.com/mwrock/kitchen-nodes/pull/42) ([stromweld](https://github.com/stromweld))
- Updated travis-ci tests and unit tests


## [0.9.1](https://github.com/mwrock/kitchen-nodes/tree/0.9.1) (2017-03-19)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.9.0...0.9.1)

**Closed issues:**

- Failed to complete \#converge action: \[undefined method `\[\]' for \#\<WinRM::Output:0x4adaab8\>\] [\#32](https://github.com/mwrock/kitchen-nodes/issues/32)

**Merged pull requests:**

- Fix winrm [\#33](https://github.com/mwrock/kitchen-nodes/pull/33) ([mwrock](https://github.com/mwrock))

## [v0.9.0](https://github.com/mwrock/kitchen-nodes/tree/v0.9.0) (2017-01-13)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.8.0...v0.9.0)

**Closed issues:**

- Trouble searching the node [\#23](https://github.com/mwrock/kitchen-nodes/issues/23)
- Working Example: Nginx Balancer + 2 App Nodes [\#22](https://github.com/mwrock/kitchen-nodes/issues/22)

**Merged pull requests:**

- Add support for loading roles from .rb and .json [\#31](https://github.com/mwrock/kitchen-nodes/pull/31) ([dullyouth](https://github.com/dullyouth))

## [v0.8.0](https://github.com/mwrock/kitchen-nodes/tree/v0.8.0) (2016-09-24)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.7.0...v0.8.0)

**Closed issues:**

- Searching fqdn and ip on windows breaks [\#28](https://github.com/mwrock/kitchen-nodes/issues/28)
- Nodes returned from search are missing attributes from ohai? [\#24](https://github.com/mwrock/kitchen-nodes/issues/24)
- policyfile support [\#14](https://github.com/mwrock/kitchen-nodes/issues/14)

**Merged pull requests:**

- run kitchen tests in travis/docker [\#27](https://github.com/mwrock/kitchen-nodes/pull/27) ([mwrock](https://github.com/mwrock))
- update rubies in travis [\#26](https://github.com/mwrock/kitchen-nodes/pull/26) ([mwrock](https://github.com/mwrock))
- Put node object to the "nodes\_path" if defined [\#25](https://github.com/mwrock/kitchen-nodes/pull/25) ([legal90](https://github.com/legal90))

## [v0.7.0](https://github.com/mwrock/kitchen-nodes/tree/v0.7.0) (2016-03-08)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.6.6...v0.7.0)

**Implemented enhancements:**

- Added support for windows 2008R2 [\#18](https://github.com/mwrock/kitchen-nodes/pull/18) ([johnsmyth](https://github.com/johnsmyth))

**Fixed bugs:**

- Fix device filtering breaking for IPv6 interfaces [\#15](https://github.com/mwrock/kitchen-nodes/pull/15) ([vervas](https://github.com/vervas))

## [v0.6.6](https://github.com/mwrock/kitchen-nodes/tree/v0.6.6) (2016-02-12)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.6.5...v0.6.6)

**Fixed bugs:**

- kitchen-nodes fails serverspec test on 2012 node due to unpopulated IP address [\#11](https://github.com/mwrock/kitchen-nodes/issues/11)
- Shave extra newline off fqdn [\#13](https://github.com/mwrock/kitchen-nodes/pull/13) ([watkinsv-hp](https://github.com/watkinsv-hp))

## [v0.6.5](https://github.com/mwrock/kitchen-nodes/tree/v0.6.5) (2016-02-11)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.6.4...v0.6.5)

**Fixed bugs:**

- kitchen-nodes provisioner needs kitchen-sync sftp finder [\#10](https://github.com/mwrock/kitchen-nodes/issues/10)

## [v0.6.4](https://github.com/mwrock/kitchen-nodes/tree/v0.6.4) (2016-01-27)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.6.0...v0.6.4)

**Fixed bugs:**

- Error: Sandbox directory has not yet been created [\#9](https://github.com/mwrock/kitchen-nodes/issues/9)

## [v0.6.0](https://github.com/mwrock/kitchen-nodes/tree/v0.6.0) (2015-12-14)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.5.0...v0.6.0)

**Implemented enhancements:**

- Expand the run\_list into the automatic=\>recipes attribute [\#8](https://github.com/mwrock/kitchen-nodes/pull/8) ([eherot](https://github.com/eherot))

## [v0.5.0](https://github.com/mwrock/kitchen-nodes/tree/v0.5.0) (2015-10-11)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.4.1...v0.5.0)

**Implemented enhancements:**

- Feature/adding fqdn [\#7](https://github.com/mwrock/kitchen-nodes/pull/7) ([faja](https://github.com/faja))

## [v0.4.1](https://github.com/mwrock/kitchen-nodes/tree/v0.4.1) (2015-08-14)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.4.0...v0.4.1)

## [v0.4.0](https://github.com/mwrock/kitchen-nodes/tree/v0.4.0) (2015-08-12)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.3.4...v0.4.0)

## [v0.3.4](https://github.com/mwrock/kitchen-nodes/tree/v0.3.4) (2015-08-04)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.3.3...v0.3.4)

## [v0.3.3](https://github.com/mwrock/kitchen-nodes/tree/v0.3.3) (2015-07-30)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.3.2...v0.3.3)

**Implemented enhancements:**

- Update IP finder to work for CentOS 7.1 [\#6](https://github.com/mwrock/kitchen-nodes/pull/6) ([joerocklin](https://github.com/joerocklin))

## [v0.3.2](https://github.com/mwrock/kitchen-nodes/tree/v0.3.2) (2015-06-26)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.3.1...v0.3.2)

**Fixed bugs:**

- Fix search\(\) for currently provisioned node [\#4](https://github.com/mwrock/kitchen-nodes/pull/4) ([ustuehler](https://github.com/ustuehler))

## [v0.3.1](https://github.com/mwrock/kitchen-nodes/tree/v0.3.1) (2015-05-11)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.3.0...v0.3.1)

## [v0.3.0](https://github.com/mwrock/kitchen-nodes/tree/v0.3.0) (2015-05-10)
[Full Changelog](https://github.com/mwrock/kitchen-nodes/compare/v0.2.0...v0.3.0)

**Implemented enhancements:**

- Include .kitchen.yml attributes to the node file at 'normal' scope. [\#2](https://github.com/mwrock/kitchen-nodes/pull/2) ([jcejohnson](https://github.com/jcejohnson))

## [v0.2.0](https://github.com/mwrock/kitchen-nodes/tree/v0.2.0) (2015-04-21)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
