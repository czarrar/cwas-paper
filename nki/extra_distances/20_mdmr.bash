#!/usr/bin/env bash

scan="short"
strategy="compcor"
res=4
sm=""

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
distbase="${cwasdir}/${scan}/try_distances"


###
# MDMR
###

# Use 800 ROIs but with all possible distances
k="0800"
#measures="pearson spearman kendall concordance euclidean chebyshev mahalanobis"
measures="concordance"
#measures="mahalanobis"
for measure in ${measures}; do
    echo "K of ${k} with ${measure}"
    sdistdir="${distbase}/${measure}_k${k}_to_k${k}"
    
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
done
