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





