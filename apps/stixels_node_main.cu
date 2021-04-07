// This file is part of Instance Stixels:
// https://github.com/tudelft-iv/instance-stixels
//
// Copyright (c) 2019 Thomas Hehn.
//
// Instance Stixels is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Instance Stixels is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Instance Stixels. If not, see <http://www.gnu.org/licenses/>.


#include <ros/ros.h>
#include "stixels_node.h"

int main(int argc, char** argv) {
    ros::init(argc, argv, "instance_stixels");

    ros::NodeHandle nh;

    std::string onnxfile;
    if(!nh.getParam("instance_stixels/onnxfile", onnxfile)){
        ROS_ERROR("Failed to get onnxfile parameter.");
        return 1;
    }
    ROS_INFO("Creating InstanceStixels wrapper...");
    InstanceStixelsNode stixels_node(nh, onnxfile);

    ROS_INFO("Spinning Instancestixels...");
    ros::spin();
    ROS_INFO("InstanceStixels done...");

    return 0;
}

