#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/development+motion"
outdir="${basedir}/development+motion"

echo "COMPCOR"

echo "Age"
sdistdir="${outdir}/cwas/rois_random_k0800_only"

echo "...transforming distances"
curdir=$(pwd)
cd /home2/data/Projects/CWAS/share/lib
./transform_cor.R ${sdistdir}/subdist.desc 30 12
cd $curdir

echo "...deleting old mdmr results"
rm -r ${sdistdir}/age+motion_sex+tr.mdmr

#echo "...archiving old mdmr results"
#archive="${sdistdir}/archive_old_sdists_and_perms"
#mkdir ${archive} 2> /dev/null
#mv ${sdistdir}/age+motion_sex+tr.mdmr ${archive}/

echo "Age + Motion"
connectir_mdmr.R -i ${sdistdir} \
    --formula "sex + tr + mean_FD + age" \
    --model ${indir}/subinfo/02_details.csv \
    --factors2perm "age,mean_FD" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age+motion_sex+tr.mdmr

#echo "Age + Motion with MeanGlobal"
#connectir_mdmr.R -i ${outdir}/cwas/compcor_kvoxs_smoothed \
#    --formula "sex + tr + mean_FD + age + meanGcor" \
#    --model ${indir}/subinfo/02_details_with_gcors.csv \
#    --factors2perm "age,mean_FD" \
#    --permutations 14999 \
#    --forks 1 --threads 10 \
#    --memlimit 12 \
#    --save-perms \
#    --ignoreprocerror \
#    age+motion_sex+tr+meanGcor.mdmr


#####



###
# CORRECT
###

cd /home2/data/Projects/CWAS/share/lib/clustcor

distbase="${outdir}/cwas"
roidir="${outdir}/rois"

# Only ROI-based
#ks="0025 0050 0100 0200 0400 0800 1600 3200 6400"
ks="0800"
for k in ${ks}; do
    echo "K of ${k}"
    
    sdistdir="${distbase}/rois_random_k${k}_only"
    mdmrdir="${sdistdir}/age+motion_sex+tr.mdmr"
    roifile="${roidir}/rois_random_k${k}.nii.gz"
    
    ./le_correcter.R ${sdistdir} ${mdmrdir} ${roifile}
done
