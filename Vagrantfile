# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false

  # Réglages provider VirtualBox (communs)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "8192"
    vb.cpus   = 4
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Provisioning commun minimal (idempotent)
  common_shell = <<-SHELL
    set -e
    export DEBIAN_FRONTEND=noninteractive

    # Paquets de base (idempotent)
    apt-get update -y
    apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release

    # SSH : s'assurer que le service est démarré
    systemctl enable --now ssh || true

    # Swap off (recommandé pour Kubernetes)
    swapoff -a || true
    sed -i.bak '/ swap / s/^/#/' /etc/fstab || true
  SHELL

  # MASTER 1 (Leader)
  config.vm.define "master1", primary: true do |m1|
    m1.vm.hostname = "master1"
    m1.vm.network "private_network", ip: "192.168.56.101"
    m1.vm.provision "shell", inline: common_shell
  end

  # MASTER 2
  config.vm.define "master2" do |m2|
    m2.vm.hostname = "master2"
    m2.vm.network "private_network", ip: "192.168.56.102"
    m2.vm.provision "shell", inline: common_shell
  end

  # MASTER 3
  config.vm.define "master3" do |m3|
    m3.vm.hostname = "master3"
    m3.vm.network "private_network", ip: "192.168.56.103"
    m3.vm.provision "shell", inline: common_shell
  end

  # WORKER 1
  config.vm.define "worker1" do |w1|
    w1.vm.hostname = "worker1"
    w1.vm.network "private_network", ip: "192.168.56.104"
    w1.vm.provision "shell", inline: common_shell
  end
end
