#!/bin/sh

UMFCHECK=../umfcheck

# check models against specs
$UMFCHECK foo_model.lua foo_spec.lua
$UMFCHECK robot_model1.lua robot_spec.lua
$UMFCHECK robot_model2.lua robot_spec.lua

# check specs against metaspec
$UMFCHECK foo_spec.lua meta_spec.lua
$UMFCHECK robot_spec.lua meta_spec.lua
$UMFCHECK kdl_frame_spec.lua meta_spec.lua

