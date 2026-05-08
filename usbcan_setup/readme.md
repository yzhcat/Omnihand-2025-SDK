```bash
lsusb
Bus 003 Device 011: ID 0c72:0012 PEAK System XCAN-USB FD
```
ATTRS{idVendor}=="0c72", ATTRS{idProduct}=="0012"

替换99-can-auto.rules 
ATTRS{idVendor}=="xxxx", ATTRS{idProduct}=="xxxx"替换为0c72, 0012

```bash
chmod +x /home/ros/bdodsdk/Omnihand-2025-SDK/setup_can.sh

sudo cp 99-can-auto.rules /etc/udev/rules.d/99-can-auto.rules

sudo systemctl restart udev

sudo udevadm control --reload-rules
sudo udevadm trigger
```

```bash
sudo visudo
```
添加以下内容：
# OmniHand CAN配置免密码
%sudo ALL=(ALL) NOPASSWD: /sbin/ifconfig can0 *
%sudo ALL=(ALL) NOPASSWD: /sbin/ip link set can0 *