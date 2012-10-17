#
# Cookbook Name:: djatoka
# Recipe:: default
#
# Copyright 2012, UTL
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "ark"

### install djatoka and symlinks
ark 'adore-djatoka' do
  version '1.1'
  url "http://#{node['djatoka']['source_server']}/#{node['djatoka']['source_path']}/adore-djatoka-1.1.tar.gz"
  prefix_root "/opt"
  prefix_home "/opt"
  checksum  '2eebdb81ceadb20aebe56e5d4bcbc9b4969170609a410ca03f6049a68013d3a9'
  owner "#{node['tomcat']['user']}"
end

##make required changes to env.sh
template "#{node['djatoka']['djatoka_path']}/bin/env.sh" do
  source "env.sh.erb"
  owner "#{node['tomcat']['user']}"
  group "root"
  mode 0755
end

###move the war file into place and wait a few moments for tomcat to load it before proceeding
bash "move_djatoka_war" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  cp -f #{node['djatoka']['djatoka_path']}/dist/adore-djatoka.war #{node['tomcat']['webapp_dir']}/
  EOH
  not_if "test -f #{node['tomcat']['webapp_dir']}/adore-djatoka.war"
  #notifies :restart, resources(:service => "tomcat"), :immediately
end

###make the djatoka logging directory
directory "#{node['djatoka']['log_dir']}" do
  owner "#{node['tomcat']['user']}"
  group "#{node['tomcat']['user']}"
  mode "0755"
  action :create
end

###put the djatoka logging file in place
template "#{node['tomcat']['webapp_dir']}/adore-djatoka/WEB-INF/classes/log4j.properties" do
  source "log4j.properties.erb"
  owner "#{node['tomcat']['user']}"
  group "#{node['tomcat']['user']}"
  mode 0755
  notifies :restart, resources(:service => "tomcat")
  retries 10
  retry_delay 10
end

##link to kdu_compress
link "/usr/local/bin/kdu_compress" do
  to "#{node['djatoka']['djatoka_path']}/bin/Linux-x86-64/kdu_compress"
end

###put the ld.conf.d file required for kdu to work
template "/etc/ld.so.conf.d/kdu_libs.conf" do
  source "kdu_libs.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

execute "ldconfig_kdu" do
  only_if "test `ldconfig -p | grep -c kdu_` -eq 0"
  command "ldconfig"
  action :run
end