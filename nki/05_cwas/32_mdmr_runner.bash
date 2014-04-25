#!/usr/bin/env bash

#./30_mdmr.bash short compcor
#./30_mdmr.bash medium compcor

#./30_mdmr.bash short compcor 1
#./30_mdmr.bash medium compcor 1

## Run through 1600 rois
#./30_mdmr.bash short compcor 0
#./30_mdmr.bash short compcor 1

## Run through all the rois - unsmoothed
#./30_mdmr.bash short compcor 0
#./30_mdmr.bash medium compcor 0
#
## Run through all the rois - smoothed
#./30_mdmr.bash short compcor 1
#./30_mdmr.bash medium compcor 1

# Run through the voxelwise smoothed/unsmoothed permutations
#./30_mdmr.bash short compcor 1

#./30_mdmr.bash long compcor 1

#./30_mdmr.bash short compcor 8
#./30_mdmr.bash medium compcor 8

#./30_mdmr_with_gcors.bash short compcor 8
#./30_mdmr_with_gcors.bash medium compcor 8

#./30_mdmr.bash short compcor 0
#./30_mdmr.bash medium compcor 0


#./30_mdmr_with_gcors.bash short compcor 0
#./30_mdmr_with_gcors.bash medium compcor 0
#./30_mdmr_with_gcors.bash short compcor 1
#./30_mdmr_with_gcors.bash medium compcor 1

#./30_mdmr.bash short compcor 0
#./30_mdmr.bash medium compcor 0
#./30_mdmr.bash short compcor 1
#./30_mdmr.bash medium compcor 1

#./30_mdmr.bash short compcor 8
#./30_mdmr.bash medium compcor 8

#./30_mdmr.bash short compcor 12

# Redo with transformed correlations
#./30_mdmr.bash short compcor 8
#./30_mdmr.bash medium compcor 8

./30_mdmr_with_gcors.bash short compcor 8
./30_mdmr_with_gcors.bash medium compcor 8

./33_mdmr_gsr.bash short compcor 8
./33_mdmr_gsr.bash medium compcor 8
