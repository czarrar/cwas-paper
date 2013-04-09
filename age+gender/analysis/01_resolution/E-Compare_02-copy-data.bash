#!/bin/bash

# Copies over the differing files
# across the ROI and voxelwise analyses

base="/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
cdir="${base}/combined_rois+voxelwise"
ks="rois_k0025 rois_k0050 rois_k0100 rois_k0200 rois_k0400 rois_k0800 rois_k1600 rois_k3200 rois_k6400 voxelwise"

# Create directory
mkdir $cdir

# Copy over standard brain and brain mask
cp ${base}/voxelwise/bg_image.nii.gz ${cdir}/standard_4mm.nii.gz
cp ${base}/voxelwise/mask.nii.gz ${cdir}/mask.nii.gz

# Copy over the zstats for age
for k in ${ks}; do
    echo "age - $k"
    infile="${base}/${k}/age+gender_with-meanFD_15k_rhs.mdmr/zstats_age.nii.gz"
    outfile="${cdir}/age_${k}.nii.gz"
    3dcalc -a ${infile} -expr '(a-1.65) * step(a-1.65)' -prefix ${outfile}
done

# Copy over the zstats for sex
for k in ${ks}; do
    echo "sex - $k"
    infile="${base}/${k}/age+gender_with-meanFD_15k_rhs.mdmr/zstats_sex.nii.gz"
    outfile="${cdir}/sex_${k}.nii.gz"
    3dcalc -a ${infile} -expr '(a-1.65) * step(a-1.65)' -prefix ${outfile}
done


# Below will compare distribution across different measures at k=3200

ks="rois_random_k3200 rois-to-voxel_k3200 rois-to-voxel_random_k3200"

# Copy over the zstats for age
for k in ${ks}; do
    echo "age - $k"
    infile="${base}/${k}/age+gender_with-meanFD_15k_rhs.mdmr/zstats_age.nii.gz"
    outfile="${cdir}/age_${k}.nii.gz"
    3dcalc -a ${infile} -expr '(a-1.65) * step(a-1.65)' -prefix ${outfile}
done

# Copy over the zstats for sex
for k in ${ks}; do
    echo "sex - $k"
    infile="${base}/${k}/age+gender_with-meanFD_15k_rhs.mdmr/zstats_sex.nii.gz"
    outfile="${cdir}/sex_${k}.nii.gz"
    3dcalc -a ${infile} -expr '(a-1.65) * step(a-1.65)' -prefix ${outfile}
done



# Below will compare distribution across different rois-to-voxel measures
# for corrected and uncorrected data

ks="rois-to-voxel_k0025 rois-to-voxel_k0050 rois-to-voxel_k0100 rois-to-voxel_k0200 rois-to-voxel_k0400 rois-to-voxel_k0800 rois-to-voxel_k1600 rois-to-voxel_k3200 rois-to-voxel_k6400"
#ks="voxelwise"

# Copy over the zstats for age
for k in ${ks}; do
    echo "age - $k"
    infile="${base}/${k}/age+gender_with-meanFD_15k_rhs.mdmr/zstats_age.nii.gz"
    outfile="${cdir}/age_${k}.nii.gz"
    3dcalc -a ${infile} -expr '(a-1.65) * step(a-1.65)' -prefix ${outfile}
done

# Copy over the zstats for sex
for k in ${ks}; do
    echo "sex - $k"
    infile="${base}/${k}/age+gender_with-meanFD_15k_rhs.mdmr/zstats_sex.nii.gz"
    outfile="${cdir}/sex_${k}.nii.gz"
    3dcalc -a ${infile} -expr '(a-1.65) * step(a-1.65)' -prefix ${outfile}
done

# Copy over the fdr corrected zstats for age
for k in ${ks}; do
    echo "age - $k"
    infile="${base}/${k}/age+gender_with-meanFD_15k_rhs.mdmr/zstats_fdr_age.nii.gz"
    outfile="${cdir}/fdr_age_${k}.nii.gz"
    3dcalc -a ${infile} -expr '(a-1.65) * step(a-1.65)' -prefix ${outfile}
done

# Copy over the fdr corrected zstats for sex
for k in ${ks}; do
    echo "sex - $k"
    infile="${base}/${k}/age+gender_with-meanFD_15k_rhs.mdmr/zstats_fdr_sex.nii.gz"
    outfile="${cdir}/fdr_sex_${k}.nii.gz"
    3dcalc -a ${infile} -expr '(a-1.65) * step(a-1.65)' -prefix ${outfile}
done
