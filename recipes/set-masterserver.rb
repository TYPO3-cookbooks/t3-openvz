# On master servers, add a cronjob to write /etc/masterserver into every VE
if node.virtualization.role == "host"
  template "/usr/local/sbin/create-masterserver-info.sh" do
    source "host/create-masterserver-info.sh.erb"
    owner "root"
    mode "755"
  end

  execute "Write master server information into each VE" do
    command "/usr/local/sbin/create-masterserver-info.sh"
    user "root"
  end
end

# On virtual servers, set the node attribute if the file was changed
if node.virtualization.role == "guest"
  if File.exists?("/etc/masterserver")
    node.set['virtualization']['masterserver'] = File.read("/etc/masterserver").chomp
  else
    node.set['virtualization']['masterserver'] = 'undefined'
  end
end
