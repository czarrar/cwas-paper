#!/bin/bash

###
# This will take the larger subject distances and split it based on the bootstraps
###

base="/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
folds=$(count -digits 2 1 10)


###
# First for ROIs
###

for k in ${ks}; do
    echo "k: ${k}"
    sdir="${base}/rois-to-voxel_random_k${k}"
    mkdir ${sdir}/partial_subdists
    
    for fold in ${folds}; do
        echo "...fold: ${fold}"
        connectir_filter_subdist.R \
            --model ../z_details2.csv \
            --subdist ${sdir}/subdist.desc \
            --whichsubs z_whichsubs_10fold_${fold}.txt \
            --forks 1 --threads 12 --memlimit 12 \
            ${sdir}/partial_subdists/fold${fold}
    done
    
done

# Remove the subject distances (only keep gower distance matrices)
rm /home2/data/Projects/CWAS/age+gender/01_resolution/cwas/rois-to-voxel_random_k*/partial_subdists/fold??_subdist.*


###
# Second for voxelwise (NO NEED TO DO HERE CUZ DONE IN vox2parcel folder)
###

