Description
===========

OpenVZ Setup (Host only)
------------
This cookbook installs OpenVZ on the host machine with OpenVZ packages.

Additionally, it adds a watchdog script, which alerts `root`, if VEs exceed their limits.



Ohai Plugins (Guest only)
================

This cookbook ships with two Ohai plugins:

* `openvz-ipaddress`: This detects the `ipaddress` and `ip6address` correctly inside OpenVZ containers. As these aren't bound to a usual `ethX` or so, vanilla Ohai does not recognize the addresses.
* `openvz-hostdetection`: Stores the node, on which the container is running in `node['virtualization']['host]`. It therefore uses the `openvz-host` hint, which is [placed from the outside](https://github.com/TYPO3-cookbooks/openvz/blob/7e2771ee3393af0e238e3fad2ebf0a1cb4effaf4/recipes/ohai.rb#L42-L46) into the containers file system.