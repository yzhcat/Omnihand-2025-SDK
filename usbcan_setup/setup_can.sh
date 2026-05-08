#!/bin/bash
# OmniHand 2025 CAN设备自动配置脚本
# 支持PEAK System XCAN-USB FD设备

echo "[CAN Config] Starting CAN interface configuration..."

# 检查can0是否存在
if ! ip link show can0 &>/dev/null; then
    echo "[CAN Config] can0 interface not found, waiting for device..."
    sleep 1
fi

# 确保can0处于关闭状态
sudo ifconfig can0 down 2>/dev/null

# 设置CAN FD参数（与SDK中的配置一致）
echo "[CAN Config] Setting CAN parameters..."
sudo ip link set can0 type can bitrate 1000000 sample-point 0.8 dbitrate 5000000 dsample-point 0.8 fd on

# 启动can0接口
echo "[CAN Config] Bringing up can0 interface..."
sudo ifconfig can0 up

# 验证配置
if ip link show can0 | grep -q "UP"; then
    echo "[CAN Config] CAN interface configured successfully!"
    echo "[CAN Config] can0 status: UP"
else
    echo "[CAN Config] Failed to configure CAN interface"
    exit 1
fi