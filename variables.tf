#
# Environment Variables
#
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "avi_password" {}
variable "avi_username" {}
variable "avi_vsphere_user" {}
variable "avi_vsphere_password" {}
variable "avi_vsphere_server" {}
variable "docker_registry_username" {}
variable "docker_registry_password" {}
variable "docker_registry_email" {}

#
# Other Variables
#
variable "vcenter" {
  type = map
  default = {
    dc = "wdc-06-vc12"
    cluster = "wdc-06-vc12c01"
    datastore = "wdc-06-vc12c01-vsan"
    resource_pool = "wdc-06-vc12c01/Resources"
    folder = "jlepthienK8s" # needs to be changed if duplicate this repo
    networkMgmt = "vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt"
  }
}

variable "controller" {
  default = {
    cpu = 16
    memory = 32768
    disk = 256
    cluster = false
    version = "21.1.1-9045"
    wait_for_guest_net_timeout = 4
    private_key_path = "~/.ssh/cloudKey"
    environment = "VMWARE"
    dns =  ["10.206.8.130", "10.206.8.131"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "true" # true is required for LSC Cloud
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
    aviCredsJsonFile = "~/.avicreds.json"
    public_key_path = "~/.ssh/cloudKey.pub"
  }
}

variable "jump" {
  type = map
  default = {
    name = "jump"
    cpu = 2
    memory = 4096
    disk = 20
    public_key_path = "~/.ssh/cloudKey.pub"
    private_key_path = "~/.ssh/cloudKey"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-focal-20.04-cloudimg-template"
    avisdkVersion = "21.1.1"
    username = "ubuntu"
  }
}

variable "client" {
  type = map
  default = {
    name = "client-jlepthien" # needs to be changed if duplicate this repo
    cpu = 2
    memory = 4096
    disk = 20
    public_key_path = "~/.ssh/cloudKey.pub"
    private_key_path = "~/.ssh/cloudKey"
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-focal-20.04-cloudimg-template"
    username = "ubuntu"
    netplan_file_path = "/etc/netplan/50-cloud-init.yaml"
    ip_mgmt = "10.206.112.114/22" # needs to be changed if duplicate this repo
    gw = "10.206.112.1"
    ip_vip = "100.64.133.253" # needs to be changed if duplicate this repo
    dns_servers = "10.206.8.130, 10.206.8.131"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.10.7"
    aviPbAbsentUrl = "https://github.com/tacobayle/ansiblePbAviAbsent"
    aviPbAbsentTag = "v1.58"
    aviConfigureUrl = "https://github.com/tacobayle/aviConfigure"
    aviConfigureTag = "v6.04"
    k8sInstallUrl = "https://github.com/tacobayle/ansibleK8sInstall"
    k8sInstallTag = "v1.6"
  }
}

variable "vmw" {
  default = {
    name = "dc1_vCenter"
    datacenter = "wdc-06-vc12"
    dhcp_enabled = "true"
    domains = [
      {
        name = "avi.com"
      }
    ]
    management_network = {
      name = "vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt"
      dhcp_enabled = "true"
      exclude_discovered_subnets = "true"
      vcenter_dvs = "true"
    }
    network_vip = {
      name = "vxw-dvs-34-virtualwire-120-sid-6120119-wdc-06-vc12-avi-dev116"
      ipStartPool = "190" # needs to be changed if duplicate this repo
      ipEndPool = "199" # needs to be changed if duplicate this repo
      cidr = "100.64.133.0/24"
      type = "V4"
      exclude_discovered_subnets = "true"
      vcenter_dvs = "true"
      dhcp_enabled = "no"
    }
    default_waf_policy = "System-WAF-Policy"
    serviceEngineGroup = [
      {
        name = "Default-Group"
        ha_mode = "HA_MODE_SHARED"
        min_scaleout_per_vs = 2
        buffer_se = 1
        vcenter_folder = "jlepthienK8s" # needs to be changed if duplicate this repo
      },
    ]
    virtualservices = {
      dns = [
        {
          name = "app-dns"
          services: [
            {
              port = 53
            }
          ]
        }
      ]
    }
    kubernetes = {
      workers = {
        count = 2
      }
      ako = {
        deploy = false
      }
      clusters = [
        {
          name = "cluster1" # cluster name
          netplanApply = true
          username = "ubuntu" # default username dor docker and to connect
          version = "1.21.3-00" # k8s version
          namespaces = [
            {
              name= "ns1"
            },
            {
              name= "ns2"
            },
            {
              name= "ns3"
            },
          ]
          ako = {
            namespace = "avi-system"
            version = "1.5.1"
            helm = {
              url = "https://projects.registry.vmware.com/chartrepo/ako"
            }
            values = {
              AKOSettings = {
                disableStaticRouteSync = "false"
              }
              L7Settings = {
                serviceType = "ClusterIP"
                shardVSSize = "SMALL"
              }
            }
          }
          serviceEngineGroup = {
            name = "seg-cluster1"
            ha_mode = "HA_MODE_SHARED"
            min_scaleout_per_vs = "2"
            buffer_se = 1
            vcenter_folder = "jlepthienK8s" # needs to be changed if duplicate this repo
            se_name_prefix = "cluster1"
          }
          networks = {
            pod = "192.168.0.0/16"
          }
          docker = {
            version = "5:20.10.7~3-0~ubuntu-bionic"
          }
          interface = "ens224" # interface used by k8s
          cni = {
            url = "https://docs.projectcalico.org/manifests/calico.yaml"
            name = "calico" # calico or antrea
          }
          master = {
            cpu = 8
            memory = 16384
            disk = 80
            network = "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-bionic-18.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
          worker = {
            cpu = 4
            memory = 8192
            disk = 40
            network = "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-bionic-18.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
        },
        {
          name = "cluster2"
          netplanApply = true
          username = "ubuntu"
          version = "1.21.3-00"
          namespaces = [
            {
              name= "ns1"
            },
            {
              name= "ns2"
            },
            {
              name= "ns3"
            },
          ]
          ako = {
            namespace = "avi-system"
            version = "1.5.1"
            helm = {
              url = "https://projects.registry.vmware.com/chartrepo/ako"
            }
            values = {
              AKOSettings = {
                disableStaticRouteSync = "false"
              }
              L7Settings = {
                serviceType = "NodePortLocal"
                shardVSSize = "SMALL"
              }
            }
          }
          serviceEngineGroup = {
            name = "Default-Group"
            ha_mode = "HA_MODE_SHARED"
            min_scaleout_per_vs = 2
            buffer_se = 1
            vcenter_folder = "jlepthienK8s" # needs to be changed if duplicate this repo
          }
          networks = {
            pod = "192.168.1.0/16"
          }
          docker = {
            version = "5:20.10.7~3-0~ubuntu-bionic"
          }
          interface = "ens224"
          cni = {
            url = "https://github.com/vmware-tanzu/antrea/releases/download/v1.2.3/antrea.yml"
            name = "antrea"
            enableNPL = true
          }
          master = {
            count = 1
            cpu = 8
            memory = 16384
            disk = 80
            network = "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-bionic-18.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
          worker = {
            cpu = 4
            memory = 8192
            disk = 40
            network = "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"
            wait_for_guest_net_routable = "false"
            template_name = "ubuntu-bionic-18.04-cloudimg-template"
            netplanFile = "/etc/netplan/50-cloud-init.yaml"
          }
        }
      ]
    }
  }
}