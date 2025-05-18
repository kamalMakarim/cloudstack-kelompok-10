## Konfigure the network

### Network yang dipilih

- Host : 192.168.106.162/23
- Gateway : 192.168.1

### Tambahkan konfigurasi agar netplan presist on reboot

```bash
sudo nano /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

Isi dengan

```cfg
network: {config: disabled}
```

### Konfigurasi netplan

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Isi dengan

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: false
      dhcp6: false
      optional: true
  bridges:
    cloudbr0:
      addresses: [192.168.106.162/23]
      routes:
        - to: default
          via: 192.168.106.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      interfaces: [enp1s0]
      dhcp4: false
      dhcp6: false
      parameters:
        stp: false
        forward-delay: 0
```

Apply configuration dengan

```bash
sudo -i
netplan generate
netplan apply
reboot
```

Uji coba konfigurasi

```bash
ifconfig
ping google.com
```

## Installing Hardware Resource Monitoring Tool

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install htop lynx duf -y
sudo apt install bridge-utils
```

## Konfigurasi LVM untuk penyimpanan

Tidak diperlukan kecuali jika menggunakan logical volume

```bash
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv
```

## Installing Netwrok service and text editor

```bash
apt-get install openntpd openssh-server sudo vim tar -y
apt-get install intel-microcode -y
passwd root
```

## SSH

### Enable SSH root login

```bash
sed -i '/#PermitRootLogin prohibit-password/a PermitRootLogin yes' /etc/ssh/sshd_config
```

Kemudian restart sshd dengan

```bash
service ssh restart
```

atau

```bash
systemctl restart sshd.service
```

### Pengecekan konfigurasi SSH

```bash
sudo nano /etc/ssh/sshd_config
```

## Clousdstack Installation

### Import repository key cloudsta

```bash
sudo -i
mkdir -p /etc/apt/keyrings
wget -O- http://packages.shapeblue.com/release.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/cloudstack.gpg > /dev/null
echo deb [signed-by=/etc/apt/keyrings/cloudstack.gpg] http://packages.shapeblue.com/cloudstack/upstream/debian/4.18 / > /etc/apt/sources.list.d/cloudstack.list
```

### Periksa repostiory yang duah ditambahin

```bash
nano /etc/apt/sources.list.d/cloudstack.list
```

Pastikan terdapat

```
deb [signed-by=/etc/apt/keyrings/cloudstack.gpg] http://packages.shapeblue.com/cloudstack/upstream/debian/4.18 /
```

### Install cloudstack dan mysql server

```bash
apt-get update -y
apt-get install cloudstack-management mysql-server
```

### Configure mysql

```bash
nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

menambahkan line berikut di bagian [mysqlid]

```cnf
server-id = 1
sql-mode="STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION"
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=1000
log-bin=mysql-bin
binlog-format = 'ROW'
```

Restart service mysql

```bash
systemctl restart mysql
```

check status mysql

```bash
systemctl status mysql
```

Deply database sebagai root dan membuat cloud user dengan password cloud

```bash
cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root:uiauiaui -i 192.168.106.162
```

confgiure primary and secondary storage

```bash
apt-get install nfs-kernel-server quota
echo "/export  *(rw,async,no_root_squash,no_subtree_check)" > /etc/exports
mkdir -p /export/primary /export/secondary
exportfs -a
```

configure NFS server

```bash
sed -i -e 's/^RPCMOUNTDOPTS="--manage-gids"$/RPCMOUNTDOPTS="-p 892 --manage-gids"/g' /etc/default/nfs-kernel-server
sed -i -e 's/^STATDOPTS=$/STATDOPTS="--port 662 --outgoing-port 2020"/g' /etc/default/nfs-common
echo "NEED_STATD=yes" >> /etc/default/nfs-common
sed -i -e 's/^RPCRQUOTADOPTS=$/RPCRQUOTADOPTS="-p 875"/g' /etc/default/quota
service nfs-kernel-server restart
```

## Configure Cloudstack host with kvm hypervisor

### Install kvm and cloudstack agent

```bash
apt-get install qemu-kvm cloudstack-agent -y
```

### Configure KVM Virtualization management

```bash
sed -i -e 's/\#vnc_listen.*$/vnc_listen = "0.0.0.0"/g' /etc/libvirt/qemu.conf

# On Ubuntu 22.04, add LIBVIRTD_ARGS="--listen" to /etc/default/libvirtd instead.

sed -i.bak 's/^\(LIBVIRTD_ARGS=\).*/\1"--listen"/' /etc/default/libvirtd
```

adding some lines

```bash
echo 'listen_tls=0' >> /etc/libvirt/libvirtd.conf
echo 'listen_tcp=1' >> /etc/libvirt/libvirtd.conf
echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf
echo 'mdns_adv = 0' >> /etc/libvirt/libvirtd.conf
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf
```

### Restart libvirtd

```bash
systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket
systemctl restart libvirtd
```

### Configureation to support Docker and Other Services

```bash
echo "net.bridge.bridge-nf-call-arptables = 0" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 0" >> /etc/sysctl.conf
sysctl -p
```

### Generate Unique Host ID

```bash
apt-get install uuid -y
UUID=$(uuid)
echo host_uuid = \"$UUID\" >> /etc/libvirt/libvirtd.conf
systemctl restart libvirtd
```

## Configure Iptables firewall and make it persistent

```bash
NETWORK=192.168.106.0/23
iptables -A INPUT -s $NETWORK -m state --state NEW -p udp --dport 111 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 111 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 2049 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 32803 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p udp --dport 32769 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 892 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 875 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 662 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 8250 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 8443 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 9090 -j ACCEPT
iptables -A INPUT -s $NETWORK -m state --state NEW -p tcp --dport 16514 -j ACCEPT

apt-get install iptables-persistent
#just answer yes yes
```

## Launch management Server

```bash
cloudstack-setup-management
systemctl status cloudstack-management
tail -f /var/log/cloudstack/management/management-server.log #if you want to troubleshoot
#wait until all services (components) running successfully
```

### Open admin dashboard

```
http://<IP ADDRESS>:8080/client
```

Login with

```
username: admin
password: password
```

## Multi-host cloud INfrastructure

### INstalling KVM host and Cloudstack agent

```bash
apt-get install qemu-kvm cloudstack-agent
```

### Configure Qemu KVM Virtualization management (libvirtd)

```bash
sed -i -e 's/\#vnc_listen.*$/vnc_listen = "0.0.0.0"/g' /etc/libvirt/qemu.conf

# On Ubuntu 22.04, add LIBVIRTD_ARGS="--listen" to /etc/default/libvirtd instead.

sed -i.bak 's/^\(LIBVIRTD_ARGS=\).*/\1"--listen"/' /etc/default/libvirtd

#configure default libvirtd configuration

echo 'listen_tls=0' >> /etc/libvirt/libvirtd.conf
echo 'listen_tcp=1' >> /etc/libvirt/libvirtd.conf
echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf
echo 'mdns_adv = 0' >> /etc/libvirt/libvirtd.conf
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf

systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket
systemctl restart libvirtd
```

### Configuration to Support Docker Services

```bash
#on certain hosts where you may be running docker and other services,
#you may need to add the following in /etc/sysctl.conf
#and then run sysctl -p: --> /etc/sysctl.conf

echo "net.bridge.bridge-nf-call-arptables = 0" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 0" >> /etc/sysctl.conf
sysctl -p
```

### Generate Unique Host ID

```bash
apt-get install uuid -y
UUID=$(uuid)
echo host_uuid = \"$UUID\" >> /etc/libvirt/libvirtd.conf
systemctl restart libvirtd
```

### Disable Firewall

```bash
systemctl ufw disable
```

### Disable Apparmour on libvirtd

```bash
ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper
```

### Configure NFS server

```bash
sed -i -e 's/^RPCMOUNTDOPTS="--manage-gids"$/RPCMOUNTDOPTS="-p 892 --manage-gids"/g' /etc/default/nfs-kernel-server
sed -i -e 's/^STATDOPTS=$/STATDOPTS="--port 662 --outgoing-port 2020"/g' /etc/default/nfs-common
echo "NEED_STATD=yes" >> /etc/default/nfs-common
sed -i -e 's/^RPCRQUOTADOPTS=$/RPCRQUOTADOPTS="-p 875"/g' /etc/default/quota
service nfs-kernel-server restart
```

### Permit SSH root login

```bash
sed -i '/#PermitRootLogin prohibit-password/a PermitRootLogin yes' /etc/ssh/sshd_config
#restart ssh service
service ssh restart
```

### Permit SSH root login

```bash
sed -i '/#PermitRootLogin prohibit-password/a PermitRootLogin yes' /etc/ssh/sshd_config
#restart ssh service
service ssh restart
```

## Managing Cloud Resource Through CLI

### Installing Cloudmonkey

```bash
snap install cloudmonkey
cloudmonkey --version
```

### Configure Cloudmonkey

```bash
cloudmonkey set url [IP Address:8080]/client/api
#example: cloudmonkey set url http://192.168.106.162:8080/client/api
cloudmonkey set apikey [apikey]
cloudmonkey set secretkey [secretkey]
cloudmonkey sync
```
