#!/usr/bin/env bash

basedir="/home2/data/Projects/CWAS"
indir="${basedir}/share/development+motion"
outdir="${basedir}/development+motion"

#echo "COMPCOR"

sdistdir="${outdir}/cwas/compcor_kvoxs_smoothed"

echo "Age"

echo "...transforming distances"
curdir=$(pwd)
cd /home2/data/Projects/CWAS/share/lib
./transform_cor.R ${sdistdir}/subdist.desc 30 12
cd $curdir

echo "...deleting old mdmr results"
rm -r ${sdistdir}/age_sex+tr.mdmr

#echo "...archiving old mdmr results"
#archive="${sdistdir}/archive_old_sdists_and_perms"
#mkdir ${archive} 2> /dev/null
#mv ${sdistdir}/age_sex+tr.mdmr ${archive}/

echo "...MDMR"
connectir_mdmr.R -i ${sdistdir} \
    --formula "sex + tr + age" \
    --model ${indir}/subinfo/02_details.csv \
    --factors2perm "age" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age_sex+tr.mdmr


echo "Age with MeanGlobal"

echo "...transforming distances"
curdir=$(pwd)
cd /home2/data/Projects/CWAS/share/lib
./transform_cor.R ${sdistdir}/subdist.desc 30 12
cd $curdir

echo "...deleting old mdmr results"
rm -r ${sdistdir}/age_sex+tr+meanGcor.mdmr

#echo "...archiving old mdmr results"
#archive="${sdistdir}/archive_old_sdists_and_perms"
#mkdir ${archive} 2> /dev/null
#mv ${sdistdir}/age_sex+tr+meanGcor.mdmr ${archive}/

echo "...MDMR"
connectir_mdmr.R -i ${sdistdir} \
    --formula "sex + tr + age + meanGcor" \
    --model ${indir}/subinfo/02_details_with_gcors.csv \
    --factors2perm "age" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age_sex+tr+meanGcor.mdmr


echo "Age + Motion"

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

echo "...MDMR"
connectir_mdmr.R -i ${outdir}/cwas/compcor_kvoxs_smoothed \
    --formula "sex + tr + mean_FD + age" \
    --model ${indir}/subinfo/02_details.csv \
    --factors2perm "age,mean_FD" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age+motion_sex+tr.mdmr


echo "Age + Motion with MeanGlobal"

echo "...transforming distances"
curdir=$(pwd)
cd /home2/data/Projects/CWAS/share/lib
./transform_cor.R ${sdistdir}/subdist.desc 30 12
cd $curdir

echo "...deleting old mdmr results"
rm -r ${sdistdir}/age+motion_sex+tr+meanGcor.mdmr

#echo "...archiving old mdmr results"
#archive="${sdistdir}/archive_old_sdists_and_perms"
#mkdir ${archive} 2> /dev/null
#mv ${sdistdir}/age+motion_sex+tr+meanGcor.mdmr ${archive}/

echo "...MDMR"
connectir_mdmr.R -i ${outdir}/cwas/compcor_kvoxs_smoothed \
    --formula "sex + tr + mean_FD + age + meanGcor" \
    --model ${indir}/subinfo/02_details_with_gcors.csv \
    --factors2perm "age,mean_FD" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age+motion_sex+tr+meanGcor.mdmr


#####

echo "GLOBAL"

sdistdir="${outdir}/cwas/global_kvoxs_smoothed"


echo "Age"

echo "...transforming distances"
curdir=$(pwd)
cd /home2/data/Projects/CWAS/share/lib
./transform_cor.R ${sdistdir}/subdist.desc 30 12
cd $curdir

echo "...deleting old mdmr results"
rm -r ${sdistdir}/age_sex+tr.mdmr

#echo "...archiving old mdmr results"
#archive="${sdistdir}/archive_old_sdists_and_perms"
#mkdir ${archive} 2> /dev/null
#mv ${sdistdir}/age_sex+tr.mdmr ${archive}/

echo "...MDMR"
time connectir_mdmr.R -i ${sdistdir} \
    --formula "sex + tr + age" \
    --model ${indir}/subinfo/02_details.csv \
    --factors2perm "age" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age_sex+tr.mdmr


echo "Age + Motion"

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

echo "...MDMR"
time connectir_mdmr.R -i ${outdir}/cwas/global_kvoxs_smoothed \
    --formula "sex + tr + mean_FD + age" \
    --model ${indir}/subinfo/02_details.csv \
    --factors2perm "age,mean_FD" \
    --permutations 14999 \
    --forks 1 --threads 10 \
    --memlimit 12 \
    --save-perms \
    --ignoreprocerror \
    age+motion_sex+tr.mdmr





# Not going to use the cwas_regress_motion dealio below

#connectir_mdmr.R -i ${outdir}/cwas_regress_motion/rois_random_k3200 \
#    --formula "sex + tr + age" \
#    --model ${indir}/subinfo/02_details.csv \
#    --factors2perm "age" \
#    --permutations 14999 \
#    --forks 1 --threads 10 \
#    --memlimit 12 \
#    --save-perms \
#    --ignoreprocerror \
#    age_sex+tr.mdmr
#
#connectir_mdmr.R -i ${outdir}/cwas_regress_motion/rois_random_k3200 \
#    --formula "sex + tr + mean_FD + age" \
#    --model ${indir}/subinfo/02_details.csv \
#    --factors2perm "age,mean_FD" \
#    --permutations 14999 \
#    --forks 1 --threads 10 \
#    --memlimit 12 \
#    --save-perms \
#    --ignoreprocerror \
#    age+motion_sex+tr.mdmr
