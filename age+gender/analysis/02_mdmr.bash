#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
sdir="${basedir}/share/age+gender"
odir="${basedir}/age+gender"

# Discovery Sample
connectir_mdmr.R -i ${odir}/cwas_discovery \
    --formula "site + run + mean_FD + age + sex" \
    --model ${sdir}/subinfo/04_discovery_df.csv \
    --permutations 14999 \
    --factors2perm "age,sex" \
    --forks 1 --threads 24 \
    --memlimit 40 \
    --save-perms \
    age+gender_15k.mdmr

# Replication Sample
connectir_mdmr.R -i ${odir}/cwas_replication \
    --formula "site + run + mean_FD + age + sex" \
    --model ${sdir}/subinfo/04_replication_df.csv \
    --permutations 14999 \
    --factors2perm "age,sex" \
    --forks 1 --threads 24 \
    --memlimit 40 \
    --save-perms \
    age+gender_15k.mdmr
