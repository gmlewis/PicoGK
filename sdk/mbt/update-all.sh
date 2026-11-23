#!/bin/bash -ex
for i in blender picogk picogkffi picogkshapes reinforce ; do
    (cd "$i" && moon update && moon test --deny-warn) || exit 1
done
