# -*- mode: ruby -*-
# vi: set ft=ruby :

# See the distribution Vagrantfile for more help

Vagrant.configure(2) do |config|

  config.vm.box = "debian/jessie64"
  config.vm.hostname = "spnl-dev"
  config.vm.provision :shell, path: "provision.sh"
  config.ssh.forward_agent = true

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.

  config.vm.network "private_network", ip: "192.168.25.10"
  config.vm.provider "virtualbox" do |vb|
 
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
    vb.memory = "1024"
  end

end
