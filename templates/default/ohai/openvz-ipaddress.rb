# This plugin aims at fixing
# - OHAI-237 (ohai ipaddress returns loopback address on servers virtualized through OpenVZ)
# - TYPO3 Forge #49481 (loopback address 127.0.0.2 confuses chef)
#
# Copyright Nathan Williams
# https://tickets.opscode.com/browse/OHAI-237?focusedCommentId=48960&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-48960

Ohai.plugin(:OpenvzIPaddress) do
  provides 'ipaddress'

  def is_openvz?
    ::File.directory?('/proc/vz')
  end
  
  def is_openvz_host?
    is_openvz? && ::File.directory?('/proc/bc')
  end
  
  collect_data(:linux) do
    if is_openvz? && !is_openvz_host?
      network['interfaces'].each do |nic, attrs|
        next unless nic =~ /(venet|veth)/
        attrs['addresses'].each do |addr, params|
          # as we use some 192.168.0.0/24 addresses on some VEs, we must prevent that this is taken as the public ipaddress
          ipaddress addr if (addr !~ /^127/ && addr !~ /^192\.168/ && params['family'] == 'inet')
        end
      end
    end
  end
end
