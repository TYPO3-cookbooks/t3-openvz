name             "t3-openvz"
maintainer       "TYPO3 Association"
maintainer_email "steffen.gebert@typo3.org"
license          "Apache 2.0"
description      "Installs/Configures openvz"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.1.3"

depends          "chef-sugar"
depends          "ohai", "< 4.0.0"
depends          "zabbix-custom-checks"
