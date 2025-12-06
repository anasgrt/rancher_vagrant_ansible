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
      vb.memory = "12288"
      vb.cpus = 4

      # Resize disk to 60GB
      unless File.exist?("./Library/VirtualBox/rancher-local-ctrl-disk001.vmdk")
        vb.customize ['createhd', '--filename', "./Library/VirtualBox/rancher-local-ctrl-disk001.vmdk", '--size', 60 * 1024]
      end
      vb.customize ['storageattach', :id, '--storagectl', 'VirtIO Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', "./Library/VirtualBox/rancher-local-ctrl-disk001.vmdk"]
    end

    node.vm.provision "shell", inline: <<-SHELL
      echo "192.168.56.10 rancher.local.test" >> /etc/hosts
      # Extend LVM to use all available disk space (including new disk)
      if [ -b /dev/sdb ]; then
        parted /dev/sdb --script mklabel gpt
        parted /dev/sdb --script mkpart primary 0% 100%
        pvcreate /dev/sdb1
        vgextend ubuntu-vg /dev/sdb1
      fi
      if [ $(vgs --noheadings -o vg_free --units g ubuntu-vg | tr -d ' Gg' | cut -d. -f1) -gt 5 ]; then
        lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
        resize2fs /dev/ubuntu-vg/ubuntu-lv
        echo "Disk extended to $(df -h / | awk 'NR==2 {print $2}')"
      fi
    SHELL
  end

  # Key Cluster
  config.vm.define "key-ctrl" do |node|
    node.vm.hostname = "key-ctrl"
    node.vm.network "private_network", ip: "192.168.56.20"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "rancher-key-ctrl"
      vb.memory = "4096"
      vb.cpus = 2

      # Resize disk to 60GB
      unless File.exist?("./Library/VirtualBox/rancher-key-ctrl-disk001.vmdk")
        vb.customize ['createhd', '--filename', "./Library/VirtualBox/rancher-key-ctrl-disk001.vmdk", '--size', 60 * 1024]
      end
      vb.customize ['storageattach', :id, '--storagectl', 'VirtIO Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', "./Library/VirtualBox/rancher-key-ctrl-disk001.vmdk"]
    end

    node.vm.provision "shell", inline: <<-SHELL
      # Extend LVM with new disk
      if [ -b /dev/sdb ]; then
        parted /dev/sdb --script mklabel gpt
        parted /dev/sdb --script mkpart primary 0% 100%
        pvcreate /dev/sdb1
        vgextend ubuntu-vg /dev/sdb1
      fi
      if [ $(vgs --noheadings -o vg_free --units g ubuntu-vg 2>/dev/null | tr -d ' Gg' | cut -d. -f1) -gt 5 ]; then
        lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
        resize2fs /dev/ubuntu-vg/ubuntu-lv
      fi
    SHELL
  end

  config.vm.define "key-worker" do |node|
    node.vm.hostname = "key-worker"
    node.vm.network "private_network", ip: "192.168.56.21"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "rancher-key-worker"
      vb.memory = "2048"
      vb.cpus = 2

      # Resize disk to 60GB
      unless File.exist?("./Library/VirtualBox/rancher-key-worker-disk001.vmdk")
        vb.customize ['createhd', '--filename', "./Library/VirtualBox/rancher-key-worker-disk001.vmdk", '--size', 60 * 1024]
      end
      vb.customize ['storageattach', :id, '--storagectl', 'VirtIO Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', "./Library/VirtualBox/rancher-key-worker-disk001.vmdk"]
    end

    node.vm.provision "shell", inline: <<-SHELL
      # Extend LVM with new disk
      if [ -b /dev/sdb ]; then
        parted /dev/sdb --script mklabel gpt
        parted /dev/sdb --script mkpart primary 0% 100%
        pvcreate /dev/sdb1
        vgextend ubuntu-vg /dev/sdb1
      fi
      if [ $(vgs --noheadings -o vg_free --units g ubuntu-vg 2>/dev/null | tr -d ' Gg' | cut -d. -f1) -gt 5 ]; then
        lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
        resize2fs /dev/ubuntu-vg/ubuntu-lv
      fi
    SHELL

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
