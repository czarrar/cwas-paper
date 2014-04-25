#!/bin/bash

scan="short"
strategy="compcor"
res=4
sm=""

basedir="/home2/data/Projects/CWAS"
roidir="${basedir}/nki/rois"

cwasdir="${basedir}/nki/cwas"
distbase="${cwasdir}/${scan}/try_distances"


cd /home2/data/Projects/CWAS/share/lib/clustcor


###
# CORRECT
###

# Only ROI-based
k="0800"
#measures="pearson spearman kendall concordance euclidean chebyshev mahalanobis"
measures="concordance"
for measure in ${measures}; do
    echo "K of ${k} with ${measure}"
    
    sdistdir="${distbase}/${measure}_k${k}_to_k${k}"
    mdmrdir="${sdistdir}/iq_age+sex+meanFD.mdmr"
    roifile="${roidir}/rois_random_k${k}.nii.gz"
    
    ./le_correcter.R ${sdistdir} ${mdmrdir} ${roifile}
done
