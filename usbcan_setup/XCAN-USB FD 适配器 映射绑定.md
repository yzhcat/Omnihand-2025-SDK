# XCAN\-USB FD 适配器 映射绑定



两个同型号 XCAN\-USB FD 适配器（VID 0c72, PID 0012），无硬件序列号（iSerial=0）

查看an\_channel\_id 都是 FFFFFFFF

```Bash
cat /sys/class/net/can0/peak_usb/can_channel_id
cat /sys/class/net/can1/peak_usb/can_channel_id
```

目标：通过写入硬件 Device Number（can\_channel\_id）实现永久绑定，不依赖物理端口。

![Image](https://internal-api-drive-stream.feishu.cn/space/api/box/stream/download/authcode/?code=MWZjZWMwOTk2OTVhMmRmNzgzNWJlOGNiNGQwOTg2MDBfNDY5ZGYwZTcwN2M3OGVmZmQ2ZTY2NDM3N2Y3NDgwNzlfSUQ6NzY1MjI5NTM2ODUxNjQ4ODQyNV8xNzgxNjg5ODY5OjE3ODE3NzYyNjlfVjM)

## 一、写入 Device ID

- 一台 Windows 电脑，用于写入设备号。

- 每次只插入一块适配器进行操作。

### 操作步骤 

https://peak\-system\.com\.cn/software/apsoftware/pcan\-view/

![Image](https://internal-api-drive-stream.feishu.cn/space/api/box/stream/download/authcode/?code=NjFjZDYxOGYwN2Q4Nzc4YjI4ZDAzN2JmY2RmNTU2ODRfZDVjZDllYjc0NWY5ZjUyOGRkZWNjZmFmNDQ1NjdiYTlfSUQ6NzY1MjI5NjMyMjk1MjcxMTE0N18xNzgxNjg5ODY5OjE3ODE3NzYyNjlfVjM)

1. **安装 PEAK 驱动和 PCAN\-View**

从 PEAK 官网下载 PCAN\-Driver 安装包，安装时勾选 PCAN\-View 组件。

2. **写入 Device ID**

    - 插入第一块适配器。

    - 打开 PCAN\-View，点击 **Connect,** 左侧列表选择设备\.点击 OK

    - 下方新增的选项卡，找到 **PCAN\-USB FD**选项, 找到**Device ID **字段。

![Image](https://internal-api-drive-stream.feishu.cn/space/api/box/stream/download/authcode/?code=ZGE1NTdlZTFiOWVkOGYyYTE0NjgxOGJhOGI4MTQwY2NfNjg5ZThhYTBlM2Q1MTZlMTQwMmVhY2FmNjUwYmQwNTFfSUQ6NzY1MjI5NjQ5MzgwMjU1NjYzNV8xNzgxNjg5ODY5OjE3ODE3NzYyNjlfVjM)

    - 设为 `1`，点击 Set。

    - 拔下第一块，插入第二块，重复操作，设为 `2`。

3. **验证写入结果**

将两块适配器插入 Linux 电脑，执行：

```Bash
cat /sys/class/net/can0/peak_usb/can_channel_id
cat /sys/class/net/can1/peak_usb/can_channel_id
```

应分别显示 `00000001`和 `00000002`（不再是 `FFFFFFFF`）。

---

## 二、编写重命名脚本 

创建脚本 `fix-can-names.sh`

### 脚本内容 

```Bash
#!/bin/bash
# 等待 can 接口出现
for i in $(seq 1 30); do
  if ls /sys/class/net/can* >/dev/null 2>&1; then break; fi
  sleep 0.2
done

renamed_left=0
renamed_right=0

for iface in $(ls /sys/class/net/ | grep '^can'); do
  # 跳过已改名的
  [[ "$iface" == "can-left" || "$iface" == "can-right" ]] && continue

  idf="/sys/class/net/$iface/peak_usb/can_channel_id"
  if [ ! -r "$idf" ]; then
    echo "[fix-can-names] WARNING: $idf not readable for $iface" >&2
    continue
  fi

  id=$(tr -d '\n\r' < "$idf")
  echo "[fix-can-names] $iface has channel_id=$id" >&2

  case "$id" in
    00000001)
      if [ "$renamed_left" -eq 0 ]; then
        echo "[fix-can-names] Renaming $iface -> can-left" >&2
        ip link set "$iface" down 2>/dev/null
        ip link set "$iface" name can-left 2>/dev/null && renamed_left=1
      fi
      ;;
    00000002)
      if [ "$renamed_right" -eq 0 ]; then
        echo "[fix-can-names] Renaming $iface -> can-right" >&2
        ip link set "$iface" down 2>/dev/null
        ip link set "$iface" name can-right 2>/dev/null && renamed_right=1
      fi
      ;;
    *)
      echo "[fix-can-names] Unknown channel_id $id for $iface, skipping" >&2
      ;;
  esac
done
```

### 赋予执行权限 

```Bash
chmod +x fix-can-names.sh
```

---

## 三、验证 

### 手动测试 

将两块适配器插入 Linux 电脑

```Bash
sudo ./fix-can-names.sh
```

输出

```Bash
[fix-can-names] can0 has channel_id=00000001
[fix-can-names] Renaming can0 -> can-left
[fix-can-names] can1 has channel_id=00000002
[fix-can-names] Renaming can1 -> can-right
```

### 检查结果 

```Bash
ls /sys/class/net/ | grep can
cat /sys/class/net/can-right/peak_usb/can_channel_id
cat /sys/class/net/can-left/peak_usb/can_channel_id
```

应输出`can-left`和 `can-right`。

### 确认 channel\_id 对应关系 

```Bash
cat /sys/class/net/can-left/peak_usb/can_channel_id   # 应为 00000001
cat /sys/class/net/can-right/peak_usb/can_channel_id  # 应为 00000002
```

---

> ```TypeScript
> ros@u22:~/Downloads$ sudo ./fix-can-names.sh 
> [fix-can-names] can0 has channel_id=00000002
> [fix-can-names] Renaming can0 -> can-right
> [fix-can-names] can1 has channel_id=00000001
> [fix-can-names] Renaming can1 -> can-left
> ros@u22:~/Downloads$ ls /sys/class/net/ | grep can
> can-left
> can-right
> ros@u22:~/Downloads$ cat /sys/class/net/can-right/peak_usb/can_channel_id
> 00000002
> ros@u22:~/Downloads$ cat /sys/class/net/can-left/peak_usb/can_channel_id
> 00000001
> ros@u22:~/Downloads$ 
> ```
> 
> 

---

## 后续使用说明 

- 应用程序中统一使用接口名 `can-left`和 `can-right`，不再依赖 `can0`/`can1`。

- 如需交换左右手角色，只需在脚本中将 `00000001`与 `00000002`对应的目标名互换即可。



# LINUX pcan

4. **验证写入结果**

将两块适配器插入 Linux 电脑，执行：

```Bash
lsmod | grep can
----------
pcan                  208896  0
can_dev                32768  1 pcan
```

**PEAK 官方 ****`pcan`****字符驱动**（`lsmod`里的 `pcan`模块）。与`peak_usb`驱动暴露信息的方式完全不同——

- `peak_usb`→ 走 socketcan 原生路径 → 有 `peak_usb/can_channel_id`

- `pcan`驱动 → 走 `/proc/pcan`\+ `/dev/pcanX`→ **没有那个 sysfs 节点**



使用 `cat /proc/pcan` 命令

```Bash
cat /proc/pcan
---------------
*------------- PEAK-System CAN interfaces (www.peak-system.com) -------------
*------------- Release_20220929_n (8.15.2) Jun  9 2026 11:22:34 --------------
*------------------- [mod] [isa] [pci] [pec] [usb] [net] --------------------
*--------------------- 2 interfaces @ major 507 found -----------------------
*n -type- -ndev- --base-- irq --btr- --read-- --write- --irqs-- -errors- status
32  usbfd   can0 ffffffff 002 0x001c 00000000 00000000 00000000 00000000 0x0000
33  usbfd   can1 ffffffff 001 0x001c 00000000 00000000 00000000 00000000 0x0000
```

其中irq的下方 显示的就是**Device ID**

应分别显示 `001`和 `002`

## 二、编写重命名脚本 

创建脚本 `fix-can-names-pcan.sh`

### 脚本内容 

```Bash
#!/bin/bash
# 通过 /proc/pcan 的 irq 列(=Device Number)区分左右手

# 等 can 接口出现
for i in $(seq 1 50); do
  if [ -f /proc/pcan ] && ls /sys/class/net/can* >/dev/null 2>&1; then
    grep -q "usbfd.*can" /proc/pcan 2>/dev/null && break
  fi
  sleep 0.2
done

[ ! -f /proc/pcan ] && echo "[fix-can] /proc/pcan not found, abort" >&2 && exit 1

renamed_left=0
renamed_right=0

while read -r n type ndev base irq rest; do
  [ "$type" != "usbfd" ] && continue
  [[ ! "$ndev" =~ ^can[0-9] ]] && continue

  devnum="$irq"
  echo "[fix-can] $ndev -> Device Number=$devnum"

  case "$devnum" in
    001|1)
      if [ "$renamed_left" -eq 0 ]; then
        echo "[fix-can] Renaming $ndev -> can-left"
        ip link set "$ndev" down
        if ip link set "$ndev" name can-left; then
          renamed_left=1
        else
          echo "[fix-can] ERROR: failed to rename $ndev to can-left" >&2
        fi
      fi
      ;;
    002|2)
      if [ "$renamed_right" -eq 0 ]; then
        echo "[fix-can] Renaming $ndev -> can-right"
        ip link set "$ndev" down
        if ip link set "$ndev" name can-right; then
          renamed_right=1
        else
          echo "[fix-can] ERROR: failed to rename $ndev to can-right" >&2
        fi
      fi
      ;;
    *)
      echo "[fix-can] WARNING: unknown Device Number '$devnum' on $ndev" >&2
      ;;
  esac
done < <(grep "usbfd" /proc/pcan)

# 如果改名成功，把接口 up 起来（可选）
for iface in can-left can-right; do
  if ip link show "$iface" >/dev/null 2>&1; then
    ip link set "$iface" up type can bitrate 1000000 2>/dev/null || true
  fi
done
```



### 赋予执行权限 

```Bash
chmod +x fix-can-names-pcan.sh
```

---

## 三、验证 

### 测试 

将两块适配器插入 Linux 电脑

```Bash
sudo ./fix-can-names-pcan.sh
```

输出

```Bash
[fix-can] can0 -> Device Number=002
[fix-can] Renaming can0 -> can-right
[fix-can] can1 -> Device Number=001
[fix-can] Renaming can1 -> can-left
```

### 检查结果 

```Bash
cat /proc/pcan
-------------
*------------- PEAK-System CAN interfaces (www.peak-system.com) -------------
*------------- Release_20220929_n (8.15.2) Jun  9 2026 11:22:34 --------------
*------------------- [mod] [isa] [pci] [pec] [usb] [net] --------------------
*--------------------- 2 interfaces @ major 507 found -----------------------
*n -type- -ndev- --base-- irq --btr- --read-- --write- --irqs-- -errors- status
32  usbfd can-left ffffffff 002 0x001c 00000000 00000000 00000000 00000000 0x0000
33  usbfd can-right ffffffff 001 0x001c 00000000 00000000 00000000 00000000 0x0000
```

应输出`can-left` 001 和 `can-right` 002。

---

> ```SQL
> ./canset_pcan.sh
>  cat /proc/pcan
> -------------
> *------------- PEAK-System CAN interfaces (www.peak-system.com) -------------
> *------------- Release_20220929_n (8.15.2) Jun  9 2026 11:22:34 --------------
> *------------------- [mod] [isa] [pci] [pec] [usb] [net] --------------------
> *--------------------- 2 interfaces @ major 507 found -----------------------
> *n -type- -ndev- --base-- irq --btr- --read-- --write- --irqs-- -errors- status
> 32  usbfd can-left ffffffff 002 0x001c 00000000 00000000 00000000 00000000 0x0000
> 33  usbfd can-right ffffffff 001 0x001c 00000000 00000000 00000000 00000000 0x0000
> ```
> 
> 

---

## 后续使用说明 

- 应用程序中统一使用接口名 `can-left`和 `can-right`，不再依赖 `can0`/`can1`。




