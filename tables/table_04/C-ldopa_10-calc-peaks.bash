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
sdist="${base}/ldopa/cwas/compcor_kvoxs_smoothed"
indir="${sdist}/ldopa_subjects+meanFD.mdmr/cluster_correct_v05_c05/easythresh"
outdir="${base}/tables/table_04/data_ldopa"
mkdir ${outdir} 2> /dev/null

# Input Files
factor="conditions"
mask="${sdist}/mask.nii.gz"
zstat="${indir}/zstat_${factor}.nii.gz"
thresh_zstat="${indir}/thresh_zstat_${factor}.nii.gz"
clust="${indir}/cluster_mask_zstat_${factor}.nii.gz"



###
# COPY OVER NEEDED FILES
###

cmd="3dcopy ${clust} ${outdir}/cluster_mask.nii.gz"
echo $cmd
$cmd

cmd="3dcopy ${zstat} ${outdir}/zstat.nii.gz"
echo $cmd
$cmd

cmd="3dcopy ${thresh_zstat} ${outdir}/thresh_zstat.nii.gz"
echo $cmd
$cmd

cmd="3dcopy ${mask} ${outdir}/mask.nii.gz"
echo $cmd
$cmd



###
# SMOOTH
###

# Output Files
nonsignif="${outdir}/tmp_non_thresh_zstat_mask.nii.gz"
smoothed_signif="${outdir}/thresh_zstat_sm${fwhm}.nii.gz"
smoothed_nonsignif="${outdir}/non_thresh_zstat_sm${fwhm}.nii.gz"
smoothed_zstat="${outdir}/zstat_sm${fwhm}.nii.gz"

# Get everything but thresholded significant values
cmd="3dcalc -a ${thresh_zstat} -b ${mask} -expr 'step(b)-step(a)' -prefix ${nonsignif}"
echo $cmd
3dcalc -a ${thresh_zstat} -b ${mask} -expr 'step(b)-step(a)' -prefix ${nonsignif}

# Within significant clusters
cmd="3dBlurInMask -input ${zstat} -FWHM ${fwhm} -Mmask ${clust} -prefix ${smoothed_signif}"
echo $cmd
$cmd

# Outside within significant clusters
cmd="3dBlurInMask -input ${zstat} -FWHM ${fwhm} -mask ${nonsignif} -prefix ${smoothed_nonsignif}"
echo $cmd
$cmd

# Combined
cmd="3dcalc -a ${smoothed_signif} -b ${smoothed_nonsignif} -expr 'a+b' -prefix ${smoothed_zstat}"
echo $cmd
3dcalc -a ${smoothed_signif} -b ${smoothed_nonsignif} -expr 'a+b' -prefix ${smoothed_zstat}


###
# Maximize with Extrema
###

peaks="${outdir}/maxima.txt"
smoothed_peaks="${outdir}/maxima_sm${fwhm}.txt"

# regular
echo ""
cmd="3dExtrema -maxima -volume -closure -sep_dist ${peak_dist} -mask_file ${mask} ${thresh_zstat}"
echo "$cmd"
$cmd > ${peaks}
echo "output - ${peaks}"

# smoothed
echo ""
cmd="3dExtrema -maxima -volume -closure -sep_dist ${peak_dist} -mask_file ${mask} ${smoothed_signif}"
echo "$cmd"
$cmd > ${smoothed_peaks}
echo "output - ${smoothed_peaks}"
