#!/bin/bash

"""
This script copies over the MDMR output files into a special directory for SUMA viz
"""


###
# Setup Variables
###

# Paths
base="/home2/data/Projects/CWAS/age+gender/03_robustness"
cdir="${base}/viz_cwas"

# ROI subpaths
#ks="rois_k0025 rois_k0050 rois_k0100 rois_k0200 rois_k0400 rois_k0800 rois_k1600 rois_k3200 rois_k6400 voxelwise"
ks="rois_random_k1600 rois_random_k3200"

# Samples
samples="discovery replication"

# Thresholds
threshs="1.5 2 2.5 3"


###
# Setup Basic Output
###

# Create dictionary
mkdir $cdir

# Copy over standard brain and brain mask
cp ${base}/discovery_rois_random_k3200/bg_image.nii.gz ${cdir}/standard_4mm.nii.gz
cp ${base}/discovery_rois_random_k3200/mask2.nii.gz ${cdir}/mask.nii.gz


###
# Loop through discovery/replication
###

# Plain Data
for sample in ${samples}; do
    
    # Copy over the zstats for age
    for k in ${ks}; do
        for thresh in ${threshs}; do
            echo "age - $k"
            infile="${base}/cwas/${sample}_${k}/age+gender_15k.mdmr/fdr_logp_age.nii.gz"
            outfile="${cdir}/fdr_age_${k}_${sample}_thr${thresh}.nii.gz"
            3dcalc -a ${infile} -expr "(a-${thresh}) * step(a-${thresh})" -prefix ${outfile}
        done
    done
    
    # Copy over the zstats for sex
    for k in ${ks}; do
        for thresh in ${threshs}; do
            echo "sex - $k"
            infile="${base}/cwas/${sample}_${k}/age+gender_15k.mdmr/fdr_logp_sex.nii.gz"
            outfile="${cdir}/fdr_sex_${k}_${sample}.nii.gz"
            3dcalc -a ${infile} -expr "(a-${thresh}) * step(a-${thresh})" -prefix ${outfile}
        done
    done
    
done

# Overlap
## Copy over the zstats for age
for k in ${ks}; do
    
    for thresh in ${threshs}; do
        echo "age - $k"
        d_infile="${base}/cwas/discovery_${k}/age+gender_15k.mdmr/fdr_logp_age.nii.gz"
        r_infile="${base}/cwas/replication_${k}/age+gender_15k.mdmr/fdr_logp_age.nii.gz"
        outfile="${cdir}/fdr_age_${k}_overlap_thr${thresh}.nii.gz"
        3dcalc -a ${d_infile} -b ${r_infile} -expr "1*step(a-${thresh}) + 2*step(b-${thresh})" -prefix ${outfile}
    done
    
done   
## Copy over the zstats for sex
for k in ${ks}; do
    
    for thresh in ${threshs}; do
        echo "sex - $k"
        d_infile="${base}/cwas/discovery_${k}/age+gender_15k.mdmr/fdr_logp_sex.nii.gz"
        r_infile="${base}/cwas/replication_${k}/age+gender_15k.mdmr/fdr_logp_sex.nii.gz"
        outfile="${cdir}/fdr_sex_${k}_overlap_thr${thresh}.nii.gz"
        3dcalc -a ${d_infile} -b ${r_infile} -expr "1*step(a-${thresh}) + 2*step(b-${thresh})" -prefix ${outfile}
    done
    
done


