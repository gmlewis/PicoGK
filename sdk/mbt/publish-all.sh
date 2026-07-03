#!/bin/bash -ex
for i in blender picogk picogkffi picogkshapes ; do
    pushd $i && moon update && moon publish && popd
done
