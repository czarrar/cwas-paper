#!/usr/bin/env bash

# This script computes distances using the IQ dataset and 800 ROIs
# Several different distance measures will be computed

scan="short"
strategy="compcor"
res=4

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

roidir="${basedir}/nki/rois"

outbase="${basedir}/nki/cwas"
mkdir $outbase 2> /dev/null


###
# Distances
###

outdir="${outbase}/${scan}/try_distances"
mkdir -p ${outdir} 2> /dev/null

# Use 800 ROIs but with all possible distances
k="0800"
#measures="pearson spearman kendall concordance euclidean chebyshev mahalanobis"
#measures="kendall"
#measures="mahalanobis"
measures="concordance"
for measure in ${measures}; do
    echo "K of ${k} with ${measure}"
    # Subject Distances
    time connectir_subdist.R \
        --method ${measure} \
        --infuncs1 ${subdir}/${scan}_${strategy}_rois_random_k${k}.txt \
        --in2D1 \
        --ztransform \
        --bg ${roidir}/standard_${res}mm.nii.gz \
        --forks 1 --threads 12 \
        --memlimit 12 \
        ${outdir}/${measure}_k${k}_to_k${k}
done
