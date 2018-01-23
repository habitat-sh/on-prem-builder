# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.4"
  config.vm.provision "shell", path: "scripts/install-hab.sh", privileged: true
  config.vm.provision "shell", path: "scripts/hab-sup.service.sh", privileged: true
  config.vm.provision "shell", path: "scripts/provision.sh", privileged: true

  config.vm.network "forwarded_port", guest: 9636, host: 9636
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.network "forwarded_port", guest: 9631, host: 9631

  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 4
  end

  config.vm.provider "vmware_fusion" do |v|
    v.vmx["memsize"] = "4096"
    v.vmx["numvcpus"] = "2"
  end
end
