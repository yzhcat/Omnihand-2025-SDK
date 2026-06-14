/*
 * @Author: huangshiheng@agibot.com
 * @Date: 2025-11-10 17:22:05
 * @LastEditors: huangshiheng
 * @LastEditTime: 2025-11-10 17:34:35
 * @FilePath: /Omnihand-2025-SDK/src/c_agibot_hand_base.cc
 * @Description: 
 * 
 * Copyright (c) 2025 by huangshiheng@agibot.com, All Rights Reserved. 
 */
// Copyright (c) 2025, Agibot Co., Ltd.
// OmniHand 2025 SDK is licensed under Mulan PSL v2.

#include <c_agibot_hand_base.h>
#include "implementation/c_agibot_hand_can/c_agibot_hand_can.h"
#include "implementation/c_agibot_hand_rs/c_agibot_hand_rs.h"

namespace YAML {
template <>
struct convert<AgibotHandO10::HardwareConf> {
  static bool decode(const Node& node, AgibotHandO10::HardwareConf& hardware_conf) {
    if (!node.IsMap()) return false;
    if (node["type"]) {
      hardware_conf.device = node["type"].as<std::string>();
    }
    if (node["options"]) {
      hardware_conf.options = node["options"];
    } else {
      hardware_conf.options = YAML::Node(YAML::NodeType::Null);
    }
    return true;
  }
};
}  // namespace YAML


std::unique_ptr<AgibotHandO10> AgibotHandO10::createHand(
    unsigned char device_id,
    const std::string& canfd_iface,
    EHandType hand_type)
{
    auto hand = std::make_unique<AgibotHandCanO10>(canfd_iface);
    hand->Reset(device_id, hand_type);
    return hand;
}

std::unique_ptr<AgibotHandO10> AgibotHandO10::createHand(
    unsigned char device_id,
    unsigned char canfd_id,
    EHandType hand_type) {
    // 将数字 ID 转换为接口名称（根据你的业务逻辑）
    std::string iface = (canfd_id == 1) ? "can0" : "can1";
    return createHand(device_id, iface, hand_type);
}
