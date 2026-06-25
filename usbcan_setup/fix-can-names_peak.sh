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
