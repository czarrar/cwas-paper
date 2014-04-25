#!/usr/bin/env bash

# This script tests differences in the peaks detected using unsmoothed vs smoothed data


###
# SETUP
###

# Settings
fwhm="6"
peak_dist="20"

# Directories
base="/home2/data/Projects/CWAS"
sdist="${base}/nki/cwas/short/compcor_kvoxs_fwhm08_to_kvoxs_fwhm08"
indir="${sdist}/iq_age+sex+meanFD.mdmr/cluster_correct_v05_c05/easythresh"

# Input Files
mask="${sdist}/mask.nii.gz"
zstat="${indir}/zstat_FSIQ.nii.gz"
thresh_zstat="${indir}/thresh_zstat_FSIQ.nii.gz"
clust="${indir}/cluster_mask_zstat_FSIQ.nii.gz"

# Output Files
smoothed_thresh_zstat="${indir}/thresh_zstat_FSIQ_sm${fwhm}.nii.gz"
peaks="${indir}/peaks_thresh_zstat_FSIQ.txt"
smoothed_peaks="${indir}/peaks_thresh_zstat_FSIQ_sm${fwhm}.txt"


###
# Smooth (within the significant clusters)
###

#cmd="3dBlurInMask -input ${zstat} -FWHM ${fwhm} -Mmask ${clust} -prefix ${smoothed_thresh_zstat}"
#echo $cmd
#$cmd


###
# Maximize with Extrema
###

# regular
echo ""
cmd="3dExtrema -maxima -volume -closure -sep_dist ${peak_dist} -mask_file ${mask} ${thresh_zstat}"
echo "$cmd"
$cmd > ${peaks}
echo "output - ${peaks}"

# smoothed
echo ""
cmd="3dExtrema -maxima -volume -closure -sep_dist ${peak_dist} -mask_file ${mask} ${smoothed_thresh_zstat}"
echo "$cmd"
$cmd > ${smoothed_peaks}
echo "output - ${smoothed_peaks}"
