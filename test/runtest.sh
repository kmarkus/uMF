#!/bin/sh
# run the tests with all installed lua interpreters, or those given
# as arguments. run from the test directory.

cd "$(dirname "$0")" || exit 1
export LUA_PATH="../?.lua;./?.lua;;"

INTERPS=${*:-"lua5.1 lua5.2 lua5.3 lua5.4 lua5.5 luajit"}
failed=0

# expect <rc> <cmd...>: run quietly, compare exit code
expect() {
    want=$1; shift
    "$@" >/dev/null 2>&1
    rc=$?
    if [ "$rc" = "$want" ]; then echo "match   $*"
    else echo "DIFFER  $* (rc $rc, want $want)"; failed=$((failed+1)); fi
}

for LUA in $INTERPS; do
    command -v "$LUA" >/dev/null || { echo "skip    $LUA (not installed)"; continue; }

    expect 0 "$LUA" regress.lua

    # check models against specs
    expect 0 "$LUA" ../umfcheck foo_model.lua foo_spec.lua
    expect 0 "$LUA" ../umfcheck robot_model1.lua robot_spec.lua
    expect 2 "$LUA" ../umfcheck robot_model2.lua robot_spec.lua
    expect 0 "$LUA" ../umfcheck kdl_frame_model.lua kdl_frame_spec.lua
    expect 2 "$LUA" ../umfcheck kdl_invalid_frame_model.lua kdl_frame_spec.lua

    # check specs against metaspec
    expect 0 "$LUA" ../umfcheck foo_spec.lua meta_spec.lua
    expect 0 "$LUA" ../umfcheck robot_spec.lua meta_spec.lua
    expect 0 "$LUA" ../umfcheck kdl_frame_spec.lua meta_spec.lua

    # examples must not crash
    expect 0 "$LUA" 3DVector.lua
    expect 0 "$LUA" simple_other.lua
    expect 0 "$LUA" uoo-test.lua
done

echo "$failed DIFFER"
[ "$failed" = 0 ]
