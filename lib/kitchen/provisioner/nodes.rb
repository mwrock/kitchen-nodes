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
        node_dir = File.join(config[:test_base_path], "nodes")
        Dir.mkdir(node_dir) unless Dir.exist?(node_dir)
        node_file = File.join(node_dir, "#{instance.name}.json")

        state = Kitchen::StateFile.new(config[:kitchen_root], instance.name).read

        node = {
          :id => instance.name,
          :automatic => {
            :ipaddress => state[:hostname]
          },
          :run_list => config[:run_list]
        }

        File.open(node_file, 'w') do |out|
          out << JSON.pretty_generate(node)
        end
      end      
    end
  end
end
