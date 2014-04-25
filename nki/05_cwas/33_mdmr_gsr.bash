#!/usr/bin/env bash

if [[ "$#" -ne 3 ]]; then
    echo "usage: $0 scan strategy smoothed"
    echo "scan: short, medium, or long"
    echo "strategy: global or compcor"
    echo "smoothed: 0 for no and 1 for yes and any other number for the exact FWHM"
    exit 1
fi

scan=$1
strategy=$2
if [[ $3 -eq 1 ]]; then
    sm="_smoothed"
elif [[ $3 -gt 1 ]]; then
    sm="_fwhm$( count -digits 2 $3 $3 | sed s/\ // )"
else
    sm=""
fi
sm="${sm}_global"

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/nki"

if [[ "$scan" == "short" ]]; then
    subdir="${indir}/subinfo/40_Set1_N104"
elif [[ "$scan" == "medium" ]]; then
    subdir="${indir}/subinfo/40_Set1_N104"
elif [[ "$scan" == "long" ]]; then
    subdir="${indir}/subinfo/40_Set2_N92"
else
    echo "unrecognized scan: ${scan}"
    exit 1
fi

cwasdir="${basedir}/nki/cwas"
distbase="${cwasdir}/${scan}"


###
# MDMR
###

# Voxelwise
echo "Voxelwise"
sdistdir="${distbase}/${strategy}_kvoxs${sm}_to_kvoxs${sm}"

#echo "...transforming distances"
#curdir=$(pwd)
#cd /home2/data/Projects/CWAS/share/lib
#./transform_cor.R ${sdistdir}/subdist.desc 30 12
#cd $curdir
#
#echo "...archiving old mdmr results"
#archive="${sdistdir}/archive_with_old_sdists"
#mkdir ${archive} 2> /dev/null
#mv ${sdistdir}/iq_age+sex+meanFD.mdmr ${archive}/

echo "...archiving old mdmr results"
archive="${sdistdir}/archive_with_old_perms"
mkdir ${archive} 2> /dev/null
mv ${sdistdir}/iq_age+sex+meanFD.mdmr ${archive}/

time connectir_mdmr.R -i ${sdistdir} \
    --formula "FSIQ + Age + Sex + ${scan}_meanFD" \
    --model ${subdir}/subject_info_with_iq_and_gcors.csv \
    --factors2perm "FSIQ" \
    --permutations 14999 \
    --forks 1 --threads 12 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    iq_age+sex+meanFD.mdmr
