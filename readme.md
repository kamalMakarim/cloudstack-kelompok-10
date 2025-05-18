## How to run the sh file
1. alter th variable at cloudstack-install.sh
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