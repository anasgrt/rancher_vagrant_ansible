# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_version = "202502.21.0"
  config.vm.box_check_update = false

  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.linked_clone = true
  end

  # Management Cluster
  config.vm.define "local-ctrl" do |node|
    node.vm.hostname = "local-ctrl"
    node.vm.network "private_network", ip: "192.168.56.10"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "rancher-local-ctrl"
      vb.memory = "6144"
      vb.cpus = 4
    end

    node.vm.provision "shell", inline: <<-SHELL
      echo "192.168.56.10 rancher.local.test" >> /etc/hosts
    SHELL
  end

  # Key Cluster
  config.vm.define "key-ctrl" do |node|
    node.vm.hostname = "key-ctrl"
    node.vm.network "private_network", ip: "192.168.56.20"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "rancher-key-ctrl"
      vb.memory = "3072"
      vb.cpus = 2
    end
  end

  config.vm.define "key-worker" do |node|
    node.vm.hostname = "key-worker"
    node.vm.network "private_network", ip: "192.168.56.21"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "rancher-key-worker"
      vb.memory = "2048"
      vb.cpus = 2
    end

    # Run Ansible provisioning after all VMs are created
    node.vm.provision "ansible" do |ansible|
      ansible.playbook = "site.yml"
      ansible.limit = "all"
      ansible.verbose = false

      # Define Ansible groups
      ansible.groups = {
        "management" => ["local-ctrl"],
        "downstream_clusters" => ["key-ctrl", "key-worker"],
        "key_cluster" => ["key-ctrl", "key-worker"],
        "key_control" => ["key-ctrl"],
        "key_workers" => ["key-worker"]
      }

      # Define host variables
      ansible.host_vars = {
        "local-ctrl" => {
          "node_ip" => "192.168.56.10",
          "node_name" => "local-ctrl",
          "node_role" => "management"
        },
        "key-ctrl" => {
          "node_ip" => "192.168.56.20",
          "node_name" => "key-ctrl",
          "node_role" => "control_plane",
          "cluster_name" => "key",
          "cluster_env" => "key",
          "cluster_num" => 1
        },
        "key-worker" => {
          "node_ip" => "192.168.56.21",
          "node_name" => "key-worker",
          "node_role" => "worker",
          "cluster_name" => "key",
          "cluster_env" => "key",
          "cluster_num" => 1,
          "control_plane_ip" => "192.168.56.20"
        }
      }

      # Optional: Enable verbose output for debugging
      # ansible.verbose = "v"

      # Optional: Add extra vars if needed
      # ansible.extra_vars = {
      #   ansible_python_interpreter: "/usr/bin/python3"
      # }
    end
  end

  # Production Cluster (uncomment to enable)
  # config.vm.define "prd-ctrl" do |node|
  #   node.vm.hostname = "prd-ctrl"
  #   node.vm.network "private_network", ip: "192.168.56.30"
  #
  #   node.vm.provider "virtualbox" do |vb|
  #     vb.name = "rancher-prd-ctrl"
  #     vb.memory = "4096"
  #     vb.cpus = 2
  #   end
  # end

  # config.vm.define "prd-worker" do |node|
  #   node.vm.hostname = "prd-worker"
  #   node.vm.network "private_network", ip: "192.168.56.31"
  #
  #   node.vm.provider "virtualbox" do |vb|
  #     vb.name = "rancher-prd-worker"
  #     vb.memory = "4096"
  #     vb.cpus = 2
  #   end
  # end

end
