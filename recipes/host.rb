#
# Cookbook Name:: openvz
# Recipe:: host
#
# Copyright 2012-2013, TYPO3 Association
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

include_recipe 'chef-sugar::default'

# prerequisites for Debian Wheezy
apt_repository "openvz" do
  uri "http://download.openvz.org/debian"
  key "http://ftp.openvz.org/debian/archive.key"
  components ["main"]
  distribution "#{node[:lsb][:codename]}-test"
  only_if { debian_after_squeeze? }
end


packages = [
  'linux-image-openvz-amd64',
  'vzctl',
  'vzquota',
  'vzdump'
]

case node[:platform]
when "debian", "ubuntu"
  packages.each do |pkg|
    package pkg do
      action :install
  end
end
when "centos"
  log "No centos support yet"
end

template "/etc/sysctl.d/openvz.conf" do
  source "host/sysctl-openvz.conf"
  mode 0644
  notifies :run, "execute[sysctl -p /etc/sysctl.d/openvz.conf]", :immediately
end

execute "sysctl -p /etc/sysctl.d/openvz.conf" do
  action :nothing
end

include_recipe "openvz::host-watchdog"
