#
# Cookbook Name:: openvz
# Recipe:: ohai
#
# Copyright 2013, TYPO3 Association
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

# On host servers, write ohai hint into the VEs private directory
if node.virtualization.role == "host"

  # path to OpenVZ's private direcotry
  vz_path = "/var/lib/vz/private/"

  # read all subdirectories from /var/lib/vz/private, but include only those that
  # have an etc/ subdirectory (just to make sure there is still something existant)
  ve_private_dirs = Dir["#{vz_path}*/"].reject{|dir| !Dir.exist?("#{dir}/etc")}

  # iterate over all VEs
  ve_private_dirs.each do |ve_private_dir|

    Chef::Log.debug "Processing #{ve_private_dir}"

    directory "#{ve_private_dir}etc/chef/ohai/hints/" do
      recursive true
    end

    # this JSON file is later picked up by ohai inside the VE and the
    # openvz-hostdetection.rb (see belog in the guest section) receives
    # that hint
    hint_file = "#{ve_private_dir}etc/chef/ohai/hints/openvz-host.json"
    file hint_file do
      content '{"host": "' + node[:fqdn] + '"}'
      notifies :run, "execute[commit #{hint_file}]"
    end

    # If we use etckeeper inside the VE, we now have to commit that changes,
    # otherwise the next chef-run will fail. Yeah, it was a great idea, to
    # introduce etckeeper. So here we're going to commit stuff:
    # This resource has to be notified by file[#{hint_file}] and only commits,
    # if there is a Git repo in place
    execute "commit #{hint_file}" do
      command <<-EOQ
      git add chef/ohai/hints/openvz-host.json
      git commit --author 'Your Host Server #{node[:fqdn]} <root@#{node[:fqdn]}>' -m 'Updating ohai hint for openvz'
      EOQ
      cwd "#{ve_private_dir}etc/"
      action :nothing
      only_if { Dir.exist?("#{ve_private_dir}etc/.git") }
    end

  end
end



# On guest servers, include ohai plugins
if node.virtualization.role == "guest"


  begin

    Chef::Log.info "Trying new ohai_plugin resource"

    # Run this if ohai version is >= 4.0.0

    ohai_plugin 'hostdetection' do
      resource :template
      source_file "ohai/openvz-hostdetection.rb"
    end

    ohai_plugin 'ipaddress' do
      resource :template
      source_file "ohai/openvz-ipaddress.rb"
    end

    ohai_plugin 'network-squeeze' do
      resource :template
      source_file "ohai/openvz-network-squeeze.rb"
      only_if { node[:lsb][:codename] == "squeeze" || node[:lsb][:codename] == "lucid"}
    end

  rescue

    Chef::Log.warn "Falling back to ohai < 4.0.0 code"

    ohai "reload openvz-hostdetection" do
      plugin "virtualization"
      action :nothing
    end

    ohai "reload openvz-ipaddress" do
      plugin "ipaddress"
      action :nothing
    end

    ['hostdetection', 'ipaddress'].each do |plugin|

      template "#{node[:ohai][:plugin_path]}/openvz-#{plugin}.rb" do
        source "ohai/openvz-#{plugin}.rb"
        notifies :reload, "ohai[reload openvz-#{plugin}]"
      end
    end

    # fix IPv6 for Debian Squeeze and Ubuntu Lucid using an old version of linux/network.rb
    ohai "reload openvz-network-squeeze" do
      plugin "network"
      action :nothing
    end
    template "#{node[:ohai][:plugin_path]}/openvz-network-squeeze.rb" do
      source "ohai/openvz-network-squeeze.rb"
      notifies :reload, "ohai[reload openvz-network-squeeze]"
      only_if { node[:lsb][:codename] == "squeeze" || node[:lsb][:codename] == "lucid"}
    end

  end

  include_recipe "ohai::default"

end
