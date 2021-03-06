#
# Cookbook Name:: raintank_stack
# Recipe:: collector
#
# Copyright (C) 2015 Jeremy Bingham
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
#

packagecloud_repo "ct/raintank" do
  type "deb"
end

package "node-raintank-collector" do
  action :upgrade
end

package "fping"

directory "/etc/raintank/collector" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

template '/etc/init/raintank-collector.conf' do
  source 'raintank-collector.conf.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
  variables({
    collector_config: node['raintank_stack']['collector_config']
  })
end

service "raintank-collector" do
  case node["platform"]
  when "ubuntu"
    if node["platform_version"].to_f >= 9.10
      provider Chef::Provider::Service::Upstart
    end
  end
  action [ :enable, :start ]
end

collector_name =  node['raintank_stack']['collector_name'] || node.hostname
template node['raintank_stack']['collector_config'] do
  source 'config.json.erb'
  mode '0644'
  owner 'root'
  group 'root'
  action :create
  variables({
    collector_name: collector_name,
    num_cpus: node['raintank_stack']['num_cpus'] || node.cpu.total,
    server_url: node['raintank_stack']['server_url'],
    api_key: node['raintank_stack']['api_key'],
    ping_port: node['raintank_stack']['ping_port']
  })
  # notifies ....
  notifies :restart, 'service[raintank-collector]'
end
