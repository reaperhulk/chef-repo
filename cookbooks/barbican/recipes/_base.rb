#
# Cookbook Name:: barbican
# Recipe:: _base
#
# Copyright (C) 2013 Rackspace, Inc.
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

include_recipe 'yum::epel'
unless Chef::Config[:solo]
    include_recipe 'authorized_keys'
end
include_recipe 'ntp'

execute "create-yum-cache" do
 command "yum -q makecache"
 action :nothing
end

ruby_block "reload-internal-yum-cache" do
  block do
    Chef::Provider::Package::Yum::YumCache.instance.reload
  end
  action :nothing
end

#TODO(reaperhulk): switch to TLS when we drop a cert on that repo
yum_key "RPM-GPG-KEY-barbican" do
  url "http://yum-repo.cloudkeep.io/gpg"
  action :add
end

#TODO(dmend): Use yum_repository resource instead of cookbook_file
cookbook_file "/etc/yum.repos.d/barbican.repo" do
  source "barbican.repo"
  mode 00644
  notifies :run, "execute[create-yum-cache]", :immediately
  notifies :create, "ruby_block[reload-internal-yum-cache]", :immediately
end

# Configure base New Relic monitoring.
unless Chef::Config[:solo]
  newrelic_info = data_bag_item(node.chef_environment, :newrelic)
  node.set[:newrelic] = node[:newrelic].merge(newrelic_info)
  node.save

  include_recipe 'barbican::_newrelic'
end
