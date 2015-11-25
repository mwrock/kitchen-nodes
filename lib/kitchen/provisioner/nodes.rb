# -*- encoding: utf-8 -*-
#
# Author:: Matt Wrock (<matt@mattwrock.com>)
#
# Copyright (C) 2015, Matt Wrock
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kitchen'
require 'kitchen/provisioner/chef_zero'
require 'kitchen/provisioner/finder'
require 'net/ping'
require 'chef/run_list'
require 'chef/role'

class Chef
  class RunList
    # Abstract Base class for expanding a run list. Subclasses must handle
    # fetching roles from a data source by defining +fetch_role+
    class RunListExpansion
      def fetch_role(name, included_by)
        kitchen_root = Dir.pwd # yes, this is really how Kitchen does it internally
        test_base_path = File.join(kitchen_root, Kitchen::DEFAULT_TEST_DIR)
        roles_dir = File.join(test_base_path, 'roles')
        role_file = File.join(roles_dir, "#{name}.json")
        Chef::Role.json_create(JSON.parse(File.read(role_file)))
      rescue Chef::Exceptions::RoleNotFound
        role_not_found(name, included_by)
      end
    end
  end
end

module Kitchen
  module Provisioner
    # Nodes provisioner for Kitchen.
    #
    # @author Matt Wrock <matt@mattwrock.com>
    class Nodes < ChefZero
      def create_sandbox
        FileUtils.rm(node_file) if File.exist?(node_file)
        create_node
        super
      end

      def create_node
        FileUtils.mkdir_p(node_dir) unless Dir.exist?(node_dir)
        template_to_write = node_template
        File.open(node_file, 'w') do |out|
          out << JSON.pretty_generate(template_to_write)
        end
      end

      def state_file
        @state_file ||= Kitchen::StateFile.new(
          config[:kitchen_root],
          instance.name
        ).read
      end

      def ipaddress
        state = state_file

        if %w(127.0.0.1 localhost).include?(state[:hostname])
          return get_reachable_guest_address(state)
        end
        state[:hostname]
      end

      def fqdn
        state = state_file
        begin
          [:username, :password].each do |prop|
            state[prop] = instance.driver[prop] if instance.driver[prop]
          end
          Finder.for_transport(instance.transport, state).find_fqdn
        rescue
          nil
        end
      end

      def recipes
        rl = config[:run_list].map { |item| ::Chef::RunList::RunListItem.new item }
        rle = ::Chef::RunList::RunListExpansion.new(chef_environment, rl)
        rle.expand
        rle.recipes
      end

      def chef_environment
        env = '_default'
        if config[:client_rb] && config[:client_rb][:environment]
          env = config[:client_rb][:environment]
        end
        env
      end

      def node_template
        {
          id: instance.name,
          chef_environment: chef_environment,
          automatic: {
            ipaddress: ipaddress,
            platform: instance.platform.name.split('-')[0].downcase,
            fqdn: fqdn,
            recipes: recipes
          },
          normal: config[:attributes],
          run_list: config[:run_list]
        }
      end

      def node_dir
        File.join(config[:test_base_path], 'nodes')
      end

      def node_file
        File.join(node_dir, "#{instance.name}.json")
      end

      def get_reachable_guest_address(state)
        active_ips(instance.transport, state).each do |address|
          next if address == '127.0.0.1'
          return address if Net::Ping::External.new.ping(address)
        end
      end

      def active_ips(transport, state)
        # inject creds into state for legacy drivers
        [:username, :password].each do |prop|
          state[prop] = instance.driver[prop] if instance.driver[prop]
        end
        ips = Finder.for_transport(transport, state).find_ips
        fail 'Unable to retrieve IPs' if ips.empty?
        ips
      end
    end
  end
end
