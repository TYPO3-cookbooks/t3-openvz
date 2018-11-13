name             "t3-openvz"
maintainer       "TYPO3 Association"
maintainer_email "steffen.gebert@typo3.org"
license          "Apache 2.0"
description      "Installs/Configures openvz"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION')) rescue '0.0.1'

depends          "chef-sugar"
depends          "ohai"
depends          "zabbix-custom-checks"
depends          "seven_zip",    "< 3.0.0"
