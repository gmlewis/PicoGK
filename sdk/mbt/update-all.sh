#!/bin/bash -ex
for i in blender picogk picogkffi picogkshapes ; do
    (cd "$i" && moon update && moon test) || exit 1
done
