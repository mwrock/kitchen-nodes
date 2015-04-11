# -*- encoding: utf-8 -*-
#
# Author:: Matt Wrock (<matt@mattwrock.com>)
#
# Copyright (C) 2015, Matt Wrock
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "kitchen"
require "kitchen/provisioner/chef_zero"
require "kitchen/provisioner/ip_finder"
require "net/ping"

module Kitchen
  module Provisioner

    # Nodes provisioner for Kitchen.
    #
    # @author Matt Wrock <matt@mattwrock.com>
    class Nodes < ChefZero

      def create_sandbox
        super
        create_node
      end

      def create_node
        state = Kitchen::StateFile.new(config[:kitchen_root], instance.name).read
        ip = state[:hostname]
        ipaddress = (ip == "127.0.0.1" || ip == "localhost") ? get_reachable_guest_address(state) : ip

        node = {
          :id => instance.name,
          :automatic => {
            :ipaddress => ipaddress
          },
          :run_list => config[:run_list]
        }

        File.open(node_file, 'w') do |out|
          out << JSON.pretty_generate(node)
        end
      end

      def node_file
        node_dir = File.join(config[:test_base_path], "nodes")
        Dir.mkdir(node_dir) unless Dir.exist?(node_dir)
        File.join(node_dir, "#{instance.name}.json")
      end

      def get_reachable_guest_address(state)
        active_ips(instance.transport, state).each do |address|
          next if address == "127.0.0.1"
          return address if Net::Ping::External.new.ping(address)
        end
        return nil
      end

      def active_ips(transport, state)
        # inject creds into state for legacy drivers
        state[:password] = instance.driver[:password] if instance.driver[:password]
        state[:username] = instance.driver[:username] if instance.driver[:username]
        IpFinder.for_transport(transport, state).find_ips
      end
    end
  end
end
