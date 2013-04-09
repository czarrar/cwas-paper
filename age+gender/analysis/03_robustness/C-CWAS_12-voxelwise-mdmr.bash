#!/usr/bin/env bash

# Uses SGE

if [[ `hostname` != 'gelert' ]]; then
    echo "Must be on gelert to run"
    exit 2
fi

basedir="/home2/data/Projects/CWAS"
sdir="${basedir}/share/age+gender"
odir="${basedir}/age+gender"

# Discovery Sample
echo "Discovery Sample"
connectir_mdmr.R -i ${odir}/cwas_discovery \
    --formula "site + run + mean_FD + age + sex" \
    --model ${sdir}/subinfo/04_discovery_df.csv \
    --permutations 14999 \
    --factors2perm "age,sex" \
    --forks 4 --threads 2 --jobs 24 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age+gender_15k.mdmr

# Replication Sample
echo "Replication Sample"
connectir_mdmr.R -i ${odir}/cwas_replication \
    --formula "site + run + mean_FD + age + sex" \
    --model ${sdir}/subinfo/04_replication_df.csv \
    --permutations 14999 \
    --factors2perm "age,sex" \
    --forks 4 --threads 2 --jobs 24 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age+gender_15k.mdmr

## Discovery Sample
#echo "Discovery Sample"
#connectir_mdmr.R -i ${odir}/cwas_discovery \
#    --formula "site + run + mean_FD + age + sex" \
#    --model ${sdir}/subinfo/04_discovery_df.csv \
#    --permutations 99 \
#    --factors2perm "age,sex" \
#    --forks 4 --threads 2 --jobs 24 \
#    --memlimit 12 \
#    --voxs 1:400 \
#    --save-perms \
#    --ignoreprocerror \
#    ztest.mdmr

