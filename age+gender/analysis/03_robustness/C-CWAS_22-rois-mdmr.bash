#!/usr/bin/env bash

# Uses SGE

#1# if [[ `hostname` != 'gelert' ]]; then
#1#     echo "Must be on gelert to run"
#1#     exit 2
#1# fi

if [[ `hostname` != 'rocky' ]]; then
    echo "Must be on rocky to run"
    exit 2
fi

basedir="/home2/data/Projects/CWAS"
sdir="${basedir}/share/age+gender/analysis/03_robustness"
odir="${basedir}/age+gender/03_robustness/cwas"

#ks="0025 0050 0100 0200 0400 0800 1600 3200"
#ks="1600"
ks="3200"

# Discovery Sample
echo "Discovery Sample"
for k in ${ks}; do
    echo "...k ${k}"
    connectir_mdmr.R -i ${odir}/discovery_rois_random_k${k} \
        --formula "site + run + mean_FD + age + sex" \
        --model ${sdir}/subinfo/04_discovery_df.csv \
        --permutations 14999 \
        --factors2perm "age,sex" \
        --forks 1 --threads 10 \
        --memlimit 30 \
        --save-perms \
        --ignoreprocerror \
        age+gender_15k.mdmr
done

# Replication Sample
echo "Replication Sample"
for k in ${ks}; do
    echo "...k ${k}"
    connectir_mdmr.R -i ${odir}/replication_rois_random_k${k} \
        --formula "site + run + mean_FD + age + sex" \
        --model ${sdir}/subinfo/04_replication_df.csv \
        --permutations 14999 \
        --factors2perm "age,sex" \
        --forks 1 --threads 10 \
        --memlimit 30 \
        --save-perms \
        --ignoreprocerror \
        age+gender_15k.mdmr
done
