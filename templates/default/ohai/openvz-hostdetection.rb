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

provides "virtualization/host"

Ohai::Log.debug "Ohai openvz-hostdetection"

openvz_metadata_from_hints = hint?('openvz-host')

if openvz_metadata_from_hints
  Ohai::Log.debug "Have openvz-host hint"
  host Mash.new
  virtualization[:host] = openvz_metadata_from_hints['host']
  Ohai::Log.debug "Set virtualization[:host] to '#{openvz_metadata_from_hints['host']}'"
else
  Ohai::Log.debug "No openvz-host hint"
end
