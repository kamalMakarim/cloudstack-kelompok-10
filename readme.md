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
# This is the network config written by 'subiquity'
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
        addresses: [1.1.1.1,8.8.8.8]
      interfaces: [enp1s0]
      dhcp4: false
      dhcp6: false
      parameters:
        stp: false
        forward-delay: 0
```
Apply configuration dengan
```bash
sudo -i  #open new shell with root privileges
netplan generate #generate config file for the renderer
netplan apply  #applies network configuration to the system
reboot #reboot the system
```
Uji coba konfigurasi
```bash
ifconfig     #check the ip address and existing interface
ping google.com  #make sure you could connect to the internet
```

### Installing Hardware Resource Monitoring Tool
```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install htop lynx duf -y
sudo apt install bridge-utils
```