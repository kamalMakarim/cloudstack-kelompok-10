
#!/bin/bash
set -e  # Exit on error

# Host : 192.168.100.45/24
# Gateway : 192.168.100.1

ROOT_PASSWORD="uiauiaui"
NETWORK=192.168.100.0
SUBNET=/24
ADDRESS=192.168.100.45
DEFAULT_GATEWAY=192.168.100.1
INTERFACE=enp1s0
DNS1=8.8.8.8
DNS2=1.1.1.1

echo 'network: {config: disabled}' | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

echo "network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: false
      dhcp6: false
      optional: true
  bridges:
    cloudbr0:
      addresses: [$ADDRESS$SUBNET]
      routes:
        - to: default
          via: $DEFAULT_GATEWAY
      nameservers:
        addresses: [$DNS1, $DNS2]
      interfaces: [$INTERFACE]
      dhcp4: false
      dhcp6: false
      parameters:
        stp: false
        forward-delay: 0" | sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null && sudo chmod 600 /etc/netplan/50-cloud-init.yaml

netplan generate
netplan apply

# to check network configuration
#ifconfig
#ping -c 4 google.com


sudo mkdir -p /etc/apt/keyrings
curl -fsSL http://packages.shapeblue.com/release.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/cloudstack.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/cloudstack.gpg] http://packages.shapeblue.com/cloudstack/upstream/debian/4.18 /" | sudo tee /etc/apt/sources.list.d/cloudstack.list > /dev/null
# check downloaded file
# sudo nano /etc/apt/sources.list.d/cloudstack.list
# make sure there is
# deb [signed-by=/etc/apt/keyrings/cloudstack.gpg] http://packages.shapeblue.com/cloudstack/upstream/debian/4.18 /

sudo apt install net-tools -y
sudo apt update -y
sudo apt upgrade -y
sudo apt install htop lynx duf -y
sudo apt install bridge-utils -y
apt-get install cloudstack-management mysql-server -y
apt-get install openntpd openssh-server sudo tar -y
apt-get install intel-microcode -y
apt-get install cloudstack-management mysql-server -y
apt-get install nfs-kernel-server quota -y
apt-get install qemu-kvm cloudstack-agent -y
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv

# Define root password as a variable


# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Configure SSH to allow root login
sed -i '/#PermitRootLogin prohibit-password/a PermitRootLogin yes' /etc/ssh/sshd_config
service ssh restart
systemctl restart sshd.service

# Configure MySQL
sed -i '/\[mysqld\]/a server-id = 1\nsql-mode="STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION"\ninnodb_rollback_on_timeout=1\ninnodb_lock_wait_timeout=600\nmax_connections=1000\nlog-bin=mysql-bin\nbinlog-format = '\''ROW'\''' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

# Set up CloudStack database
cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root:$ROOT_PASSWORD -i $ADDRESS

echo "/export  *(rw,async,no_root_squash,no_subtree_check)" > /etc/exports
mkdir -p /export/primary /export/secondary
exportfs -a

sed -i -e 's/^RPCMOUNTDOPTS="--manage-gids"$/RPCMOUNTDOPTS="-p 892 --manage-gids"/g' /etc/default/nfs-kernel-server
sed -i -e 's/^STATDOPTS=$/STATDOPTS="--port 662 --outgoing-port 2020"/g' /etc/default/nfs-common
echo "NEED_STATD=yes" >> /etc/default/nfs-common
sed -i -e 's/^RPCRQUOTADOPTS=$/RPCRQUOTADOPTS="-p 875"/g' /etc/default/quota
service nfs-kernel-server restart

# On Ubuntu 22.04, add LIBVIRTD_ARGS="--listen" to /etc/default/libvirtd instead.
sed -i.bak 's/^\(LIBVIRTD_ARGS=\).*/\1"--listen"/' /etc/default/libvirtd
# Here is the command to configure libvirtd to listen on all interfaces
# sed -i -e 's/\#vnc_listen.*$/vnc_listen = "0.0.0.0"/g' /etc/libvirt/qemu.conf

echo 'listen_tls=0' >> /etc/libvirt/libvirtd.conf
echo 'listen_tcp=1' >> /etc/libvirt/libvirtd.conf
echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf
echo 'mdns_adv = 0' >> /etc/libvirt/libvirtd.conf
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf

systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket
systemctl restart libvirtd

echo "net.bridge.bridge-nf-call-arptables = 0" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 0" >> /etc/sysctl.conf
sysctl -p

apt-get install uuid -y
UUID=$(uuid)
echo host_uuid = \"$UUID\" >> /etc/libvirt/libvirtd.conf
systemctl restart libvirtd


iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p udp --dport 111 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 111 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 2049 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 32803 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p udp --dport 32769 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 892 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 875 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 662 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 8250 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 8443 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 9090 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 16514 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p udp --dport 3128 -j ACCEPT
iptables -A INPUT -s $NETWORK$SUBNET -m state --state NEW -p tcp --dport 3128 -j ACCEPT

apt-get install iptables-persistent -y
#just answer yes yes

cloudstack-setup-management
#systemctl status cloudstack-management

snap install cloudmonkey
#cloudmonkey --version

#ask the user toinput the keys
echo "Please input your API key"
read API_KEY
echo "Please input your secret key"
read SECRET

cloudmonkey set url $ADDRESS:8080/client/api
cloudmonkey set apikey $API_KEY
cloudmonkey set secretkey $SECRET
cloudmonkey sync
