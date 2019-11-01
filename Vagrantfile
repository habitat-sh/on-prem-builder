# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 8192
    v.cpus = 2
  config.vm.synced_folder "./builder_scripts", "/home/vagrant/builder_scripts", create: true
  end

  config.vm.define "automate" do |automate|
    automate.vm.box = "bento/ubuntu-16.04"
    automate.vm.synced_folder ".", "/opt/a2-testing", create: true
    automate.vm.hostname = 'chef-automate.test'
    automate.vm.network 'private_network', ip: '192.168.33.199'
    automate.vm.provision "shell", inline: "apt-get update && apt-get install -y unzip"
    automate.vm.provision "shell", inline: "sysctl -w vm.max_map_count=262144"
    automate.vm.provision "shell", inline: "sysctl -w vm.dirty_expire_centisecs=20000"
    automate.vm.provision "shell", inline: <<-SHELL
       curl https://packages.chef.io/files/current/automate/latest/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate
       sudo ./chef-automate deploy --accept-terms-and-mlsa
    SHELL
  end

  config.vm.define "builder" do |builder|
    builder.vm.box = "bento/ubuntu-16.04"
    builder.vm.hostname = 'chef-builder.test'
    builder.vm.network 'private_network', ip: '192.168.33.200'
    builder.vm.provision "shell", inline: <<-SHELL
      sed -i '$ a 192.168.33.199 chef-automate.test' /etc/hosts
    SHELL

  end
end
