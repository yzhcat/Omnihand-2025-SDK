#!/bin/bash

# exit on error and print each command
set -e

# Note: BUILD_ROS_NODE is default OFF to avoid ROS2 dependency
# To build ROS2 node, add -DBUILD_ROS_NODE=ON to the cmake command
# bash build.sh -DBUILD_ROS_NODE=ON
# ./build.sh -DUSE_SOCKET_CAN=OFF --ZLG USB-CAN FD

if [ -d ./build/install ]; then
    rm -rf ./build/install
fi

uv run cmake -B build \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_INSTALL_PREFIX=./build/install \
    -DBUILD_PYTHON_BINDING=ON \
    $@

cmake --build build --config Debug --target install --parallel $(nproc)
