# Install and Configure Apache Cloudstack Private Cloud
Group 10:

Kamal Makarim Iskandar - 2206809841

Kevin Naufal Aryanto -  2206062850

Muhammad Billie Ellian - 2206059446

Surya Dharmasaputra Soeroso - 2206827825

---

## Video
https://youtu.be/32o2UVtfV0I

## Cloudstack Definition
Apache CloudStack adalah perangkat lunak bersifat open source untuk sistem komputasi awan yang dirancang untuk menyebarkan dan mengelola mesin virtual dalam skala jaringan yang besar. Sebagai platform IaaS (Infrastructure-as-a-Service), CloudStack merupakan platform komputasi awan yang sangat available dan sangat scalable.

## Dependencies Used
#### MySQL
open-source relational database management system (RDBMS) yang menggunakan Structured Query Language (SQL) untuk mengakses, menambah, dan mengelola data dalam basis data. MySQL banyak digunakan untuk aplikasi web dan solusi basis data tertanam karena keandalan, skalabilitas, dan kemudahan penggunaannya.

MySQL memainkan peran penting saat mengelola Apache CloudStack. MySQL berfungsi sebagai backend database utama untuk menyimpan informasi penting seperti pengguna, informasi node komputasi, dan informasi array penyimpanan.

#### Kernel-based Virtual Machine (KVM)
Sebuah teknologi virtualisasi open source yang dibangun ke dalam kernel Linux. Dengan KVM, kernel Linux dapat difungsikan sebagai hypervisor, yang memungkinkan pembuatan dan pengelolaan mesin virtual (VM). KVM digunakan karena efisiensi, skalabilitas, dan dukungannya untuk berbagai sistem operasi. KVM digunakan untuk mengelola dan mengalokasikan sumber daya perangkat keras seperti CPU, Storage, dan Jaringan dengan aman. Cloudstack menggunakan KVM sebagai lapisan abstraksi untuk melindungi dari akses langsung yang tidak aman ke perangkat keras yang tertanam.

---

## How to run the sh file
1. alter the variable at cloudstack-install.sh
```
ROOT_PASSWORD="uiauiaui"
NETWORK=192.168.100.0
SUBNET=/24
ADDRESS=192.168.100.45
DEFAULT_GATEWAY=192.168.100.1
INTERFACE=enp1s0
DNS1=8.8.8.8
DNS2=1.1.1.1
```
2. change the permission of the file to executable
```bash
chmod +x cloudstack-install.sh
```
3. run the file
```bash
sudo ./cloudstack-install.sh
```

---

## Install Explanation
### 🛠 Skrip

```bash
#!/bin/bash
set -e
```
**set -e**: Skrip akan langsung berhenti jika ada perintah yang gagal.

``` bash
ROOT_PASSWORD="uiauiaui"
NETWORK=192.168.100.0
SUBNET=/24
ADDRESS=192.168.100.45
DEFAULT_GATEWAY=192.168.100.1
INTERFACE=enp1s0
DNS1=8.8.8.8
DNS2=1.1.1.1
```
Menyimpan informasi konfigurasi IP statis, gateway default, interface fisik, dan DNS.

```bash
echo 'network: {config: disabled}' | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```
Menonaktifkan konfigurasi jaringan otomatis dari cloud-init agar tidak menimpa konfigurasi manual.

```bash 
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
```
Membuat interface bridge cloudbr0:
-    Menggunakan IP statis
-    Menambahkan default route
-    Menyetel DNS manual
-    Menonaktifkan DHCP
-    STP dimatikan dan delay forwarding diset ke 0

File Netplan disimpan di /etc/netplan/50-cloud-init.yaml dengan izin akses terbatas (chmod 600).

```bash
netplan generate
netplan apply
```
-    **netplan generate**: Menghasilkan file konfigurasi runtime dari YAML.
-    **netplan apply**: Menerapkan konfigurasi jaringan secara langsung.

```bash
# ifconfig
# ping -c 4 google.com
```
Digunakan untuk memverifikasi IP dan koneksi internet setelah konfigurasi diterapkan.



```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL http://packages.shapeblue.com/release.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/cloudstack.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/cloudstack.gpg] http://packages.shapeblue.com/cloudstack/upstream/debian/4.18 /" | sudo tee /etc/apt/sources.list.d/cloudstack.list > /dev/null
```
-    Membuat direktori untuk menyimpan keyring.
-    Mendownload dan mengonversi GPG key.
-    Menambahkan repo CloudStack 4.18 ke apt.


**GPG Key**: kunci kriptografi yang digunakan untuk memastikan integritas dan keaslian paket perangkat lunak.  Untuk memverifikasi jika paket yang diunduh memang benar berasal dari sumber official dan belum dimodifikasi.

**Keyring**: tempat (folder/file) di sistem operasi yang menyimpan satu atau lebih GPG public key

```bash
sudo apt install net-tools -y
sudo apt update -y
sudo apt upgrade -y
sudo apt install htop lynx duf -y
sudo apt install bridge-utils -y
```
Menginstal utilility monitoring, browser CLI, disk info, dan tools jaringan.

```bash
apt-get install cloudstack-management mysql-server -y
apt-get install openntpd openssh-server sudo tar -y
apt-get install intel-microcode -y
apt-get install nfs-kernel-server quota -y
apt-get install qemu-kvm cloudstack-agent -y
```
Menginstal komponen utama CloudStack (cloudstack-management, cloudstack-agent), MySQL, server waktu, SSH, KVM, NFS, dan LVM support.

```bash
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv
```
Memperluas logical volume agar seluruh ruang disk digunakan.

```bash
echo "root:$ROOT_PASSWORD" | chpasswd
```
Mengatur ulang password root.

```bash
sed -i '/#PermitRootLogin prohibit-password/a PermitRootLogin yes' /etc/ssh/sshd_config
service ssh restart
systemctl restart sshd.service
```
Mengizinkan login root melalui SSH dan me-restart service terkait.

```bash
sed -i '/\[mysqld\]/a server-id = 1\nsql-mode="STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION"\ninnodb_rollback_on_timeout=1\ninnodb_lock_wait_timeout=600\nmax_connections=1000\nlog-bin=mysql-bin\nbinlog-format = '\''ROW'\''' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
```
Menambahkan pengaturan penting MySQL untuk mendukung replikasi, binlog, dan performance tuning.

```bash
cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root:$ROOT_PASSWORD -i $ADDRESS
```
Membuat database untuk CloudStack dan melakukan setup awal.

```bash
echo "/export  *(rw,async,no_root_squash,no_subtree_check)" > /etc/exports
mkdir -p /export/primary /export/secondary
exportfs -a
```
Mengatur direktori /export sebagai share NFS untuk penyimpanan utama dan sekunder CloudStack.

```bash
sed -i -e 's/^RPCMOUNTDOPTS="--manage-gids"$/RPCMOUNTDOPTS="-p 892 --manage-gids"/g' /etc/default/nfs-kernel-server
sed -i -e 's/^STATDOPTS=$/STATDOPTS="--port 662 --outgoing-port 2020"/g' /etc/default/nfs-common
echo "NEED_STATD=yes" >> /etc/default/nfs-common
sed -i -e 's/^RPCRQUOTADOPTS=$/RPCRQUOTADOPTS="-p 875"/g' /etc/default/quota
service nfs-kernel-server restart
```
- Mengatur port tetap untuk mountd, statd, dan rquotad agar firewall bisa dikonfigurasi lebih presisi.
- Merestart service NFS untuk menerapkan perubahan.

```bash
sed -i.bak 's/^\(LIBVIRTD_ARGS=\).*/\1"--listen"/' /etc/default/libvirtd
echo 'listen_tls=0' >> /etc/libvirt/libvirtd.conf
echo 'listen_tcp=1' >> /etc/libvirt/libvirtd.conf
echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf
echo 'mdns_adv = 0' >> /etc/libvirt/libvirtd.conf
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf

systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket
systemctl restart libvirtd
```
-    Libvirt diatur untuk mendengarkan koneksi melalui TCP (port 16509).
-    Semua soket default dimatikan (mask) agar hanya service libvirtd yang aktif.

```bash
echo "net.bridge.bridge-nf-call-arptables = 0" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 0" >> /etc/sysctl.conf
sysctl -p
```
Menonaktifkan filtering paket bridge melalui iptables/arptables agar KVM bridge berjalan lancar.

```bash
apt-get install uuid -y
UUID=$(uuid)
echo host_uuid = \"$UUID\" >> /etc/libvirt/libvirtd.conf
systemctl restart libvirtd
```
Menginstal utilitas UUID dan menetapkan UUID unik ke konfigurasi libvirt.

```bash
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
```
-    Membuka semua port penting untuk NFS, libvirt, dan CloudStack Management Server.
-    Menginstal iptables-persistent untuk menyimpan aturan iptables agar tidak hilang saat reboot.

```bash
cloudstack-setup-management
```
Menyelesaikan setup untuk service cloudstack-management.

```bash
snap install cloudmonkey
cloudmonkey --version
```
Menginstal CLI resmi untuk berinteraksi dengan CloudStack API.

```bash
echo "Please input your API key"
read API_KEY
echo "Please input your secret key"
read SECRET

cloudmonkey set url http://$ADDRESS:8080/client/api
cloudmonkey set apikey $API_KEY
cloudmonkey set secretkey $SECRET
cloudmonkey sync
```
Meminta input manual API Key dan Secret dari user, lalu mengkonfigurasi cloudmonkey agar dapat melakukan request ke CloudStack Management Server.

---

### ☁️ CloudStack Configuration

#### 1. Zone Type
![Zone Type](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/1.zone-type.png?raw=true)

Zone merepresentasikan sebuah datacenter fisik. Setiap zone memiliki satu atau lebih pod, dan tiap pod memiliki beberapa host (server fisik).

#### 1.1 Core Zone
Core Zones dirancang untuk deployment di datacenter dengan kapabilitas penuh. Ini adalah opsi default dan paling kaya fitur.

#### 1.2 Edge Zone
Edge Zones adalah alternatif lightweight untuk deployment di lokasi edge (misalnya kantor cabang, lokasi remote, atau lingkungan dengan keterbatasan infrastruktur).

**Alasan Pemilihan:**  
Kelompok kami memilih **Core Zone** karena mendukung fitur jaringan lengkap untuk simulasi deployment datacenter.


### 2. Core Zone Type
![Core Zone Type](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/2.zone-core.png?raw=true)
Mengacu pada network model yang digunakan dalam zona bertipe Core. Terdapat dua opsi utama: **Advanced** dan **Basic**, serta tambahan **Security Groups** (jika memilih Advanced).


#### 2.1 Basic Network Model
Digunakan untuk cloud kecil atau internal. Semua VM berada dalam satu jaringan dan IP langsung dari jaringan fisik.

#### 2.2 Advanced Network Model
Memberikan kemampuan jaringan lengkap dan fleksibel. Mendukung topologi virtual, firewall, VPN, NAT, dan port forwarding.

**Alasan Pemilihan:**  
Kelompok memilih **Advanced** karena mendukung berbagai fitur jaringan dan cocok untuk simulasi cloud yang kompleks.

### 3. Zone Details

![Zone Details](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/3.zone-details.png?raw=true)

- **Zone Name (`kelompok-10-zone`)**  
  Nama unik yang digunakan untuk mengidentifikasi zona atau datacenter dalam CloudStack.

- **IPv4 DNS1 (`8.8.8.8`)**  
  DNS primer yang digunakan untuk resolusi nama domain, menggunakan DNS publik Google.

- **IPv4 DNS2 (`1.1.1.1`)**  
  DNS sekunder sebagai cadangan, menggunakan DNS publik Cloudflare.

- **IPv6 DNS1**  
  DNS primer untuk alamat IPv6. Zona ini tidak menggunakan konfigurasi DNS IPv6.

- **IPv6 DNS2**  
  DNS sekunder untuk alamat IPv6.

- **Internal DNS1 (`192.168.100.1`)**  
  DNS lokal untuk jaringan internal zona, mengelola nama host VM secara internal.

- **Internal DNS2 (`8.8.8.8`)**  
  DNS alternatif untuk jaringan internal jika DNS1 tidak dapat diakses.

- **Hypervisor (`KVM`)**  
  Jenis hypervisor yang menjalankan mesin virtual di zona ini. KVM adalah hypervisor open-source.

- **Network Domain**  
  Tidak ada domain jaringan khusus yang digunakan untuk VM dalam zona ini.

### 4. Public Network
![Public Network](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/4.public-network.png?raw=true)

- **Gateway (`192.168.100.1`)**  
  Alamat IP gateway yang digunakan sebagai pintu keluar jaringan publik untuk akses internet.

- **Netmask (`255.255.255.0`)**  
  Subnet mask yang menentukan ukuran dan pembagian jaringan IP.

- **VLAN/VNI**  
  Kolom ini kosong, berarti tidak menggunakan VLAN atau Virtual Network Identifier khusus untuk segmentasi jaringan.

- **Start IP (`192.168.100.100`)**  
  Alamat IP pertama dalam rentang IP yang dialokasikan untuk trafik publik, digunakan oleh VM untuk akses internet.

- **End IP (`192.168.100.110`)**  
  Alamat IP terakhir dalam rentang IP yang dialokasikan untuk trafik publik.

### 5. Pod

![Pod](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/5.pod.png?raw=true)

- **Pod Name (`kelompok-10-pod`)**  
  Nama unik untuk pod, yang merupakan bagian dari zona dan berisi host serta primary storage.

- **Reserved System Gateway (`192.168.100.1`)**  
  Alamat gateway yang digunakan untuk trafik manajemen internal CloudStack dalam pod ini.

- **Reserved System Netmask (`255.255.255.0`)**  
  Subnet mask untuk jaringan internal manajemen pod, menentukan ukuran jaringan.

- **Start Reserved System IP (`192.168.100.11`)**  
  Alamat IP awal dari rentang IP yang dicadangkan untuk trafik manajemen internal.

- **End Reserved System IP (`192.168.100.20`)**  
  Alamat IP akhir dari rentang IP yang dicadangkan untuk trafik manajemen internal.

### 6. Guest Traffic

![Guest Traffic](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/6.guest-traffic.png?raw=true)

- **VLAN/VNI Range (`3300` - `3399`)**  
  Rentang ID VLAN atau VXLAN Network Identifiers (VNI) yang digunakan untuk membawa trafik jaringan tamu (guest traffic) antar mesin virtual.  
  ID ini memisahkan trafik jaringan tamu secara virtual di dalam jaringan fisik agar isolasi dan segmentasi jaringan tetap terjaga.


### 7. Cluster

![Cluster](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/7.cluster-name.png?raw=true)

- **Cluster Name (`kelompok-10-cluster`)**  
  Nama unik untuk cluster yang merupakan kumpulan host dengan karakteristik seragam seperti hardware, hypervisor, subnet, dan shared storage.  
  Cluster ini memudahkan pengelolaan dan penjadwalan sumber daya dalam pod.

### 8. IP Address

![IP Address](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/8.ip-address.png?raw=true)

- **Host Name (`192.168.100.45`)**  
  Alamat IP atau DNS dari host fisik tempat mesin virtual akan dijalankan.

- **Username (`root`)**  
  Nama pengguna yang digunakan untuk akses ke host, biasanya adalah `root` untuk akses penuh.

- **Authentication Method (`Password`)**  
  Metode otentikasi yang dipakai untuk mengakses host, dalam hal ini menggunakan password.

- **Password (`********`)**  
  Kata sandi yang digunakan untuk login ke host dengan username yang telah ditentukan.

- **Tags**  
  Kolom untuk menambahkan label atau kategori pada host agar memudahkan manajemen.

### 9. Primary Storage

![Primary Storage](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/9.primary-storage.png?raw=true)

- **Name (`PRIMARY-STORAGE`)**  
  Nama unik untuk primary storage yang digunakan untuk menyimpan disk volume VM dalam cluster.

- **Scope (`Zone`)**  
  Lingkup cakupan storage, dalam hal ini storage berlaku untuk seluruh zona.

- **Protocol (`nfs`)**  
  Protokol yang digunakan untuk mengakses storage, di sini menggunakan NFS (Network File System).

- **Server (`192.168.100.45`)**  
  Alamat IP server storage yang menyediakan akses ke primary storage.

- **Path (`/export/primary`)**  
  Path atau direktori pada server storage tempat disk volume VM disimpan.

- **Provider (`DefaultPrimary`)**  
  Nama penyedia layanan storage, biasanya default sesuai konfigurasi CloudStack.

- **Storage tags**  
  Tag tambahan untuk klasifikasi storage, pada contoh ini sesuai dengan nama dan scope storage.

### 10. Secondary Storage

![Secondary Storage](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/10.secondary-storage.png?raw=true)

- **Provider (`NFS`)**  
  Jenis protokol atau layanan yang digunakan untuk secondary storage, di sini menggunakan NFS (Network File System).

- **Name (`SECONDARY-STORAGE`)**  
  Nama unik untuk secondary storage yang menyimpan template VM, ISO image, dan snapshot.

- **Server (`192.168.100.45`)**  
  Alamat IP server yang menyediakan secondary storage.

- **Path (`/export/secondary`)**  
  Path atau direktori pada server yang diekspor untuk secondary storage, tempat penyimpanan data terkait VM.
 
### 11. Register ISO

![Secondary Storage](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/11.register-iso.png?raw=true)

- **URL (`https://releases.ubuntu.com/jammy/ubuntu-22.04.5-desktop-amd64.iso`)**  
  Link langsung ke file ISO yang akan didaftarkan, dalam hal ini ISO Ubuntu 22.04 Desktop.

- **Name (`ubuntu-22.04`)**  
  Nama yang diberikan untuk ISO ini agar mudah dikenali dalam sistem.

- **Description (`ubuntu-22.04`)**  
  Deskripsi singkat mengenai ISO yang didaftarkan.

- **Direct download (`no`)**  
  Menandakan apakah file ISO diunduh langsung oleh CloudStack atau melalui metode lain, dalam hal ini tidak langsung.

- **Zone (`kelompok-10-zone`)**  
  Zona di mana ISO ini akan tersedia untuk digunakan.

- **Bootable (`yes`)**  
  Menunjukkan bahwa ISO ini dapat digunakan untuk booting VM.

- **OS type (`Ubuntu 22.04 LTS`)**  
  Jenis sistem operasi yang ada pada ISO, membantu dalam pengelolaan template dan VM.

- **Extractable (`no`)**  
  Menunjukkan apakah ISO ini dapat diekstrak untuk penggunaan lain, dalam hal ini tidak dapat.

- **Public (`no`)**  
  Menandakan apakah ISO ini tersedia secara publik untuk semua pengguna, di sini tidak.

- **Featured (`no`)**  
  Menandakan apakah ISO ini ditampilkan sebagai pilihan utama atau populer, di sini tidak.
 
### 12. Compute Offering

![Compute Offering](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/12.add-compute-offering.png?raw=true)

- **Name (`Large Instance`)**  
  Nama dari compute offering yang akan digunakan untuk VM.

- **Description (`2 CPU`)**  
  Deskripsi singkat yang menjelaskan spesifikasi compute offering.

- **Compute Offering Type (`Fixed offering`)**  
  Jenis offering yang sumber dayanya tetap dan tidak dapat diubah secara dinamis.

- **CPU cores (`2`)**  
  Jumlah core CPU yang dialokasikan untuk compute offering ini.

- **CPU (in MHz) (`1200`)**  
  Kecepatan CPU dalam megahertz yang dialokasikan per core.

- **Memory (in MB) (`4000`)**  
  Kapasitas RAM yang dialokasikan untuk offering ini, yaitu 4000 MB (4 GB).

- **Host Tags**  
  Kolom untuk menandai host tertentu agar compute offering ini hanya berjalan di host dengan tag tersebut, tidak diisi.

- **Network rate (Mb/s)**  
  Batas maksimum kecepatan transfer data jaringan dalam megabit per detik yang diizinkan untuk compute offering ini. Nilai ini mengontrol bandwidth jaringan yang dialokasikan ke VM.

- **Dynamic Scaling Enabled (`yes`)**  
  Menandakan bahwa fitur skalabilitas dinamis diaktifkan, memungkinkan penyesuaian sumber daya saat VM berjalan.

- **Offer HA (`no`)**  
  Menunjukkan bahwa high availability (HA) tidak diaktifkan untuk offering ini.

- **CPU Cap (`no`)**  
  Menandakan tidak ada batas maksimum penggunaan CPU yang dipaksakan.

- **Volatile (`no`)**  
  Menunjukkan offering ini tidak bersifat volatile (tidak berubah-ubah secara mendadak).

- **Deployment Planner**  
  Opsi untuk menentukan planner deployment khusus, dikosongkan pada konfigurasi ini.

### 13. Add Network

![Add Network](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/13.add-network.png?raw=true)

- **Name (`guest-network`)**  
  Nama jaringan yang dibuat untuk jaringan guest (VM).

- **Description (`guest-network`)**  
  Deskripsi singkat yang menjelaskan jaringan tersebut.

- **Zone (`kelompok-10-zone`)**  
  Zona tempat jaringan ini dibuat dan akan digunakan.

- **Domain**  
  Kolom ini kosong, biasanya untuk mengatur domain jaringan agar terisolasi di dalam zona.

- **Network domain**  
  Domain jaringan yang dapat digunakan untuk penamaan jaringan di guest network (kosong dalam konfigurasi ini).

- **Network offering (`Offering for Isolated networks with Source Nat service enabled`)**  
  Memungkinkan VM dalam jaringan ini mengakses jaringan luar melalui NAT.

- **External Id**  
  ID jaringan yang digunakan pada sistem eksternal (jika ada), dalam konfigurasi ini tidak diisi.

- **Gateway**  
  Gateway untuk jaringan ini, wajib diisi untuk jaringan Shared dan Isolated, namun tidak diisi.

- **Netmask**  
  Netmask jaringan yang digunakan, juga wajib diisi untuk Shared dan Isolated network, tidak diisi.

- **DNS 1 dan DNS 2**  
  DNS server pertama dan kedua yang digunakan oleh jaringan ini  (kosong).

### 14. Add Instance

![Add Instance](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/14.add-instance.png?raw=true)

#### 14.1 Select Deployment Infrastructure
- **Zone: `kelompok-10-zone`**  
  Zona tempat VM akan ditempatkan, biasanya mewakili satu datacenter fisik.

- **Pod: `kelompok-10-pod`**  
  Pod adalah unit dalam zona yang berisi kumpulan host dan storage.

- **Cluster: `kelompok-10-cluster`**  
  Kumpulan host yang memiliki konfigurasi hardware dan hypervisor yang sama.

- **Host: `kelompok-10`**  
  Server fisik tempat VM akan dijalankan.

#### 14.2 Template/ISO
- **ISO: `ubuntu-22.04`**  
  File image ISO yang digunakan sebagai sistem operasi untuk VM.

- **Hypervisor: `KVM`**  
  Hypervisor yang digunakan untuk menjalankan VM. Dalam hal ini, menggunakan Kernel-based Virtual Machine (KVM).

#### 14.3 Compute Offering
Compute offering menentukan spesifikasi sumber daya yang diberikan ke VM:

- **Small Instance**  
  - **Memory:** 512 MB  
  - **CPU:** Default (tidak disebutkan eksplisit)

- **Medium Instance**  
  - **CPU:** 1 CPU dengan kecepatan 0.50 GHz atau 1.00 GHz  
  - **Memory:** 1024 MB

### 15. Add Egress Rule

![Add Egress Rule](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/15.add-egress-rule.png?raw=true)

- **Source CIDR:** `10.1.1.0/24`  
  Menentukan jaringan sumber (source) yang diizinkan untuk mengakses jaringan luar. CIDR ini mengacu pada seluruh alamat IP dari 10.1.1.0 hingga 10.1.1.255.

- **Destination CIDR:** `0.0.0.0/0`  
  Menunjukkan semua alamat IP tujuan, artinya egress (lalu lintas keluar) diizinkan menuju jaringan manapun (akses ke internet secara umum).

- **Protocol:** `All`  
  Mengizinkan semua jenis protokol (TCP, UDP, ICMP, dll) untuk keluar dari VM.

- **ICMP Type / Start Port:** `All`  
  Berlaku untuk protokol ICMP atau port awal untuk protokol lainnya. Diisi `All` berarti semua tipe ICMP atau semua port awal diperbolehkan.

- **ICMP Code / End Port:** `All`  
  Berlaku untuk ICMP code atau port akhir. Diisi `All` berarti tidak ada batasan, semua diperbolehkan.

- **Action:** (default: Allow)  
  Tindakan yang diterapkan pada rule. Jika tidak disebutkan, biasanya default-nya adalah **Allow**, yang berarti lalu lintas keluar diizinkan.
 
### 16. Public IP Addresses

![Public IP Addresses](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/16.acquire-new-ip.png?raw=true)

- **IP Address:**
  - `192.168.100.102` → IP publik yang dialokasikan dan ditandai sebagai **source-nat**, digunakan untuk meneruskan koneksi internet dari VM.
  - `192.168.100.103` → IP publik lainnya yang dialokasikan untuk keperluan jaringan tamu (guest network), tapi belum digunakan sebagai source NAT.

- **State:**
  - `Allocated` → Menunjukkan bahwa IP address tersebut sudah dialokasikan ke pengguna atau sistem, tapi belum tentu sedang aktif digunakan oleh VM.

- **VM:** *(Kosong)*  
  Menandakan belum ada VM tertentu yang sedang menggunakan IP ini secara langsung.

- **Network:**
  - `guest-network` → IP ini terkait dengan jaringan tamu yang telah dibuat sebelumnya. Digunakan untuk komunikasi antara VM dan jaringan luar (internet/public).

### 17. Enable Static NAT

![Enable Static NAT](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/17.enable-static-nat.png?raw=true)

- **Name / VM ID:**
  - `VM-70742a63-5c45-4489-8d3b-39d17a427343`  
    Merupakan ID unik dari virtual machine yang akan dikaitkan dengan IP publik melalui mekanisme Static NAT.

- **IP Address:**
  - `10.1.1.79`  
    Alamat IP privat dari VM yang digunakan dalam jaringan internal (guest network).

- **State:**
  - `Running`  
    Status VM saat ini menunjukkan bahwa VM aktif dan berjalan.

- **Display Name:** *(Tidak diisi)*  
  Nama tampilan VM tidak disesuaikan, sehingga menampilkan default berupa VM ID.

- **Account:**
  - `admin`  
    Akun pengguna CloudStack yang memiliki VM ini.

- **Zone Name:**
  - `kelompok-10-zone`  
    Zona (datacenter) tempat VM tersebut dijalankan. Static NAT**  

### 18. Firewall

![Firewall](https://github.com/kamalMakarim/cloudstack-kelompok-10/blob/main/images/18.add-firewall.png?raw=true)

#### 18.1 UDP Rule
- **Source CIDR:** `0.0.0.0/0`  
  Mengizinkan lalu lintas dari semua alamat IP publik (internet).

- **Protocol:** `UDP`  
  Protokol komunikasi tanpa koneksi, sering digunakan untuk layanan seperti DNS atau streaming.

- **Start Port:** `1`  
  Port awal dari rentang port yang dibuka.

- **End Port:** `63353`  
  Port akhir dari rentang port yang dibuka.

- **State:** `Active`  
  Aturan firewall ini aktif dan sedang digunakan.

#### 18.2 TCP Rule
- **Source CIDR:** `0.0.0.0/0`  
  Mengizinkan koneksi TCP dari semua alamat IP.

- **Protocol:** `TCP`  
  Protokol komunikasi berbasis koneksi, digunakan untuk layanan seperti HTTP, SSH, dan FTP.

- **Start Port:** `1`  
  Port awal yang diizinkan.

- **End Port:** `63353`  
  Port akhir yang diizinkan.

- **State:** `Active`  
  Aturan firewall ini sedang berjalan dan berlaku. 

## Reference
https://github.com/AhmadRifqi86/cloudstack-install-and-configure/tree/main/cloudstack-install