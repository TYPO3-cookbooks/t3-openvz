#
# Cookbook Name:: openvz
# Recipe:: host-watchdog
#
# Copyright 2012, TYPO3 Association
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

files = [
  'vzstats.pl',
  'vzwatchdog.sh'
]

files.each do |file|
	template "/usr/local/sbin/#{file}" do
		source "host/#{file}"
		mode "0744"
	end
end

cron "openvz-watchdog" do
	minute "*/2"
	command "/usr/local/sbin/vzwatchdog.sh"
end