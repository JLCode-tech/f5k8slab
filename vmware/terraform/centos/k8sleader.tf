#===============================================================================
# vSphere Resources
#===============================================================================

# Create a vSphere VM in the folder #
resource "vsphere_virtual_machine" "k8sleader" {
  # VM placement #
  name             = var.vsphere_vm_name
  host_system_id   = data.vsphere_host.host.id
  resource_pool_id = data.vsphere_resource_pool.target-resource-pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vsphere_vm_folder
  tags             = [data.vsphere_tag.tag.id]

  # VM resources #
  num_cpus = var.vsphere_vcpu_number
  memory   = var.vsphere_memory_size

  # Guest OS #
  guest_id = data.vsphere_virtual_machine.template.guest_id

  # VM storage #
  disk {
    label            = "${var.vsphere_vm_name}.vmdk"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
  }

  # VM networking #
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  # Customization of the VM #
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = var.vsphere_vm_name
        domain    = var.vsphere_domain
        time_zone = var.vsphere_time_zone
      }

      network_interface {
        ipv4_address = var.vsphere_ipv4_address
        ipv4_netmask = var.vsphere_ipv4_netmask
      }

      ipv4_gateway    = var.vsphere_ipv4_gateway
      dns_server_list = ["${var.vsphere_dns_servers}"]
      dns_suffix_list = ["${var.vsphere_domain}"]
    }
  }

    #Provision All installs and services
    provisioner "remote-exec" {
        inline = [
        "mkdir /root/.ssh",
        "touch /root/.ssh/authorized_keys",
        "echo ${var.public_key} >> /root/.ssh/authorized_keys",
        "chown root:root -R /root/.ssh",
        "chmod 700 /root/.ssh",
        "chmod 600 /root/.ssh/authorized_keys",
        "systemctl stop firewalld",
        "systemctl disable firewalld",
        "swapoff -a",
        "sed -i.bak -r 's/(.+ swap .+)/#\\1/' /etc/fstab",
        "setenforce 0",
        "sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config",
        "mount bpffs -t bpf /sys/fs/bpf",
        "echo \"[kubernetes]\" > /etc/yum.repos.d/kubernetes.repo",
        "echo \"name=Kubernetes\" >> /etc/yum.repos.d/kubernetes.repo",
        "echo \"baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\" >> /etc/yum.repos.d/kubernetes.repo",
        "echo \"enabled=1\" >> /etc/yum.repos.d/kubernetes.repo",
        "echo \"gpgcheck=1\" >> /etc/yum.repos.d/kubernetes.repo",
        "echo \"repo_gpgcheck=1\" >> /etc/yum.repos.d/kubernetes.repo",
        "echo \"gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg\" >> /etc/yum.repos.d/kubernetes.repo",
        "echo \"exclude=kube*\" >> /etc/yum.repos.d/kubernetes.repo"   
        ]
        connection {
            type     = "ssh"
            user     = "root"
            password = var.vsphere_vm_password
            host    = vsphere_virtual_machine.k8sleader.default_ip_address
        }        
    }   
    provisioner "remote-exec" {
        inline = [
            "yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
            "yum install -y iscsi-initiator-utils",
            "yum install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes",
            "systemctl enable docker && systemctl start docker",
            "systemctl enable kubelet && systemctl start kubelet",
            "echo \"net.bridge.bridge-nf-call-ip6tables = 1\" >> /etc/sysctl.d/k8s.conf",
            "echo \"net.bridge.bridge-nf-call-iptables = 1\" >> /etc/sysctl.d/k8s.conf",
            "sysctl --system"   
        ]
      
        connection {
            type     = "ssh"
            user     = "root"
            password = var.vsphere_vm_password
            host    = vsphere_virtual_machine.k8sleader.default_ip_address
        }
    }
    provisioner "remote-exec" {
        inline = [
            "kubeadm init --pod-network-cidr=${var.vsphere_k8pod_network} --apiserver-advertise-address=${vsphere_virtual_machine.k8sleader.default_ip_address}",
            "mkdir -p $HOME/.kube",
            "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
            "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
            "kubectl taint nodes --all node-role.kubernetes.io/master-",
            "kubectl create -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/cilium/cilium-custom.yaml",
            "kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/metallb/metallb-namespace.yaml",
            "kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/metallb/metallb.yaml",
            "kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey=\"$(openssl rand -base64 128)\"",
            "kubectl apply -f https://raw.githubusercontent.com/JLCode-tech/f5k8slab/master/k8s/metallb/metallbconfigmap.yaml"        
        ]
      
        connection {
            type     = "ssh"
            user     = "root"
            password = var.vsphere_vm_password
            host    = vsphere_virtual_machine.k8sleader.default_ip_address
        }
    }
}