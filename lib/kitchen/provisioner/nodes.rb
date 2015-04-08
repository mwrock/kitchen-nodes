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

    class Ssh < Kitchen::Transport::Base
      class Connection < Kitchen::Transport::Base::Connection
        def node_execute(command, &block)
          return if command.nil?
          exit_code = node_execute_with_exit_code(command, &block)

          if exit_code != 0
            raise Transport::SshFailed,
              "SSH exited (#{exit_code}) for command: [#{command}]"
          end
        rescue Net::SSH::Exception => ex
          raise SshFailed, "SSH command failed (#{ex.message})"
        end

        def node_execute_with_exit_code(command, &block)
          exit_code = nil
          session.open_channel do |channel|

            channel.request_pty

            channel.exec(command) do |_ch, _success|

              channel.on_data do |_ch, data|
                yield data
              end

              channel.on_extended_data do |_ch, _type, data|
                yield data
              end

              channel.on_request("exit-status") do |_ch, data|
                exit_code = data.read_long
              end
            end
          end
          session.loop
          exit_code
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
        state = Kitchen::StateFile.new(config[:kitchen_root], instance.name).read
        ip = state[:hostname]
        ipaddress = ip == "127.0.0.1" ? get_reachable_guest_address(state) : ip

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
        instance.transport.connection(state).node_session.run_powershell_script("Get-NetIPConfiguration | % { $_.ipv4address.IPAddress}") do |address, _|
          address = address.chomp unless address.nil?
          next if address.nil? || address == "127.0.0.1"
          return address if Net::Ping::External.new.ping(address)
        end
        return nil
      end

      # This would be the equivilent of the above to call into a linux guest
      # def get_reachable_linux_guest_address(state)
      #   instance.transport.connection(state).node_execute("blah blah blah and more blah") do |address|
      #     address = address.chomp unless address.nil?
      #     next if address.nil? || address == "127.0.0.1"
      #     return address if Net::Ping::External.new.ping(address)
      #   end
      #   return nil
      # end
    end
  end
end
