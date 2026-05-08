# Copyright (c) 2025, Agibot Co., Ltd.
# OmniHand 2025 SDK is licensed under Mulan PSL v2.

from omnihand_2025 import AgibotHandO10, EHandType
import time

def main():
    # 创建左手对象
    hand = AgibotHandO10.create_hand(hand_type=EHandType.LEFT)
    print("成功连接左手设备")
    
    # 初始位置：手指伸直（所有手指关节角度为0）
    # 关节索引：1-3为拇指，4-5为食指，6为中指，7-8为无名指，9-10为小指
    # 根据API文档，关节5、6、8、10控制手指弯曲（PIP关节）
    initial_positions = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    hand.set_all_active_joint_angles(initial_positions)
    print("初始位置：手指伸直")
    time.sleep(1)
    
    # 定义手指对应的关节索引（左手）
    # 关节5: L_index_pip_joint (食指弯曲)
    # 关节6: L_middle_pip_joint (中指弯曲)
    # 关节8: L_ring_pip_joint (无名指弯曲)
    # 关节10: L_pinky_pip_joint (小指弯曲)
    finger_joints = {
        'index': 4,    # 数组索引为4（第5个关节）
        'middle': 5,   # 数组索引为5（第6个关节）
        'ring': 7,     # 数组索引为7（第8个关节）
        'pinky': 9     # 数组索引为9（第10个关节）
    }
    
    # 定义钢琴按键序列（模拟弹奏C大调音阶）
    # 每个音符对应一个手指：食指(index), 中指(middle), 无名指(ring), 小指(pinky)
    piano_sequence = [
        ('index', 0.5),   # 食指按下（约28.6度）
        ('middle', 0.5),  # 中指按下
        ('ring', 0.5),    # 无名指按下
        ('pinky', 0.5),   # 小指按下
        ('ring', 0.5),    # 无名指按下
        ('middle', 0.5),  # 中指按下
        ('index', 0.5),   # 食指按下
    ]
    
    print("\n开始弹奏钢琴...")
    
    for finger_name, press_depth in piano_sequence:
        # 创建当前位置（基于初始位置）
        current_positions = initial_positions.copy()
        
        # 获取手指对应的关节索引
        joint_idx = finger_joints[finger_name]
        
        # 设置手指弯曲角度（弧度）
        # 0 = 伸直, 1.57 = 90度弯曲
        current_positions[joint_idx] = press_depth
        
        # 发送控制命令
        hand.set_all_active_joint_angles(current_positions)
        print(f"按下 {finger_name} 手指")
        
        # 保持按键状态（模拟按键时长）
        time.sleep(0.1)
        
        # 抬起手指（恢复初始位置）
        hand.set_all_active_joint_angles(initial_positions)
        print(f"抬起 {finger_name} 手指")
        
        # 按键间隔
        time.sleep(0.1)
    
    print("\n弹奏完成！")

if __name__ == "__main__":
    main()