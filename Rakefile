require 'bundler/gem_tasks'
require 'github_changelog_generator/task'
require 'rspec/core/rake_task'
require 'cookstyle'

RSpec::Core::RakeTask.new(:test)

desc 'Run cookstyle against cookstyle'
task :style do
  sh('bundle exec cookstyle --display-cop-names --extra-details')
end

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.future_release = Kitchen::Provisioner::NODES_VERSION
  config.enhancement_labels = ['enhancement']
  config.bug_labels = ['bug']
  config.exclude_labels = %w(duplicate question invalid wontfix no_changelog)
  config.exclude_tags = [
    'v0.1.0.dev', 'v0.2.0.dev', 'v0.2.0.dev.1',
    'v0.2.0.dev.2', 'v0.2.0.dev.3', 'v0.2.0.dev.4',
    'v0.6.4.dev', 'v0.6.3', 'v0.6.2', 'v0.6.1'
  ]
end

task default: [:test, :style]
