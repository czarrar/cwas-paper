#!/usr/bin/env bash

# This script only runs ROIs for approach 1

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/age+gender/analysis/01_resolution"
outdir="${basedir}/age+gender/01_resolution/cwas"
mkdir $outdir 2> /dev/null

#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
ks="6400"
folds=$(count -digits 2 1 10)


###
# Random Parcellations
###

for k in ${ks}; do
    echo "K of ${k}"
    sdir="${outdir}/rois-to-voxel_random_k${k}"
    mdir="${sdir}/partial_mdmrs"
    mkdir ${mdir}
    
    for fold in ${folds}; do
        echo "...fold ${fold}"
        connectir_mdmr.R -i ${sdir} \
            --subdist ${sdir}/partial_subdists/fold${fold}_subdist_gower.desc \
            --formula "age + sex + mean_FD" \
            --model ${sdir}/partial_subdists/fold${fold}_model.csv \
            --permutations 14999 \
            --factors2perm "age,sex" \
            --forks 2 --threads 4 --jobs 12 \
            --memlimit 8 \
            --save-perms \
            --ignoreprocerror \
            partial_mdmrs/fold${fold}_age+gender_with-meanFD_15k.mdmr
    done
done


####
## Voxelwise
####
#
#echo "K of ${k}"
#sdir="${outdir}/voxelwise"
#mdir="${sdir}/partial_mdmrs"
#mkdir ${mdir}
#    
#for fold in ${folds}; do
#    echo "...fold ${fold}"
#    connectir_mdmr.R -i ${sdir} \
#        --subdist ${sdir}/partial_subdists/fold${fold}_subdist_gower.desc \
#        --formula "age + sex + mean_FD" \
#        --model ${sdir}/partial_subdists/fold${fold}_model.csv \
#        --permutations 14999 \
#        --factors2perm "age,sex" \
#        --forks 2 --threads 4 --jobs 12 \
#        --memlimit 8 \
#        --save-perms \
#        --ignoreprocerror \
#        partial_mdmrs/fold${fold}_age+gender_with-meanFD_15k.mdmr
#done

