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
