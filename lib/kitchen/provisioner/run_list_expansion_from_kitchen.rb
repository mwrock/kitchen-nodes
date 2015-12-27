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

require 'chef/role'

module Kitchen
  module Provisioner
    # fetches roles from kitchen roles directory
    class RunListExpansionFromKitchen < ::Chef::RunList::RunListExpansion
      def initialize(environment, run_list_items, source = nil, role_dir = nil)
        @role_dir = role_dir
        super(environment, run_list_items, source)
      end

      def fetch_role(name, included_by)
        role_file = File.join(@role_dir, "#{name}.json")
        ::Chef::Role.json_create(JSON.parse(File.read(role_file)))
      rescue ::Chef::Exceptions::RoleNotFound
        role_not_found(name, included_by)
      end
    end
  end
end
