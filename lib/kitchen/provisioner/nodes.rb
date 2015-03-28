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
require "net/ping"

module Kitchen

  module Transport
    class Winrm < Kitchen::Transport::Base
      class Connection < Kitchen::Transport::Base::Connection
        def node_session(retry_options = {})
          session(retry_options)
        end
      end
    end
  end

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
        node_dir = File.join(config[:test_base_path], "nodes")
        Dir.mkdir(node_dir) unless Dir.exist?(node_dir)
        node_file = File.join(node_dir, "#{instance.name}.json")

        state = Kitchen::StateFile.new(config[:kitchen_root], instance.name).read
        ipaddress = get_reachable_guest_address(state) || state[:hostname]

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

      def get_reachable_guest_address(state)
        instance.transport.connection(state).node_session.run_powershell_script("Get-NetIPConfiguration | % { $_.ipv4address.IPAddress}") do |address, _|
          address = address.chomp unless address.nil?
          next if address.nil? || address == "127.0.0.1"
          return address if Net::Ping::External.new.ping(address)
        end
        return nil
      end      
    end
  end
end
