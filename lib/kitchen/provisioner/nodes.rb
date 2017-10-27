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
require 'kitchen/provisioner/run_list_expansion_from_kitchen'
require 'net/ping'
require 'chef/run_list'

module Kitchen
  module Provisioner
    # Nodes provisioner for Kitchen.
    #
    # @author Matt Wrock <matt@mattwrock.com>
    class Nodes < ChefZero
      default_config :reset_node_files, false

      def create_sandbox
        create_node
      ensure
        super
      end

      def create_node
        FileUtils.mkdir_p(node_dir) unless Dir.exist?(node_dir)

        node_def = if File.exist?(node_file)
                     updated_node_def
                   else
                     node_template
                   end
        return unless node_def

        File.open(node_file, 'w') do |out|
          out << JSON.pretty_generate(node_def)
        end
      end

      def updated_node_def
        if config[:reset_node_files]
          node_template
        else
          nil
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
        rl = config[:run_list].map do |item|
          ::Chef::RunList::RunListItem.new item
        end
        rle = RunListExpansionFromKitchen.new(
          chef_environment,
          rl,
          nil,
          config[:roles_path]
        )
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

      # rubocop:disable Metrics/AbcSize
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
      # rubocop:enable Metrics/AbcSize

      def node_dir
        config[:nodes_path] || File.join(config[:test_base_path], 'nodes')
      end

      def node_file
        File.join(node_dir, "#{instance.name}.json")
      end

      def get_reachable_guest_address(state)
        active_ips(instance.transport, state).each do |address|
          next if address == '127.0.0.1'
          return address if reachable?(address)
        end
      end

      def reachable?(address)
        Net::Ping::External.new.ping(address) ||
          Net::Ping::TCP.new(address, 5985).ping ||
          Net::Ping::TCP.new(address, 5986).ping ||
          Net::Ping::TCP.new(address, 22).ping
      end

      def active_ips(transport, state)
        # inject creds into state for legacy drivers
        [:username, :password].each do |prop|
          state[prop] = instance.driver[prop] if instance.driver[prop]
        end
        ips = Finder.for_transport(transport, state).find_ips
        raise 'Unable to retrieve IPs' if ips.empty?
        ips
      end
    end
  end
end
