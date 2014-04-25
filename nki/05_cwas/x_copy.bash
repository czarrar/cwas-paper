#!/bin/bash

scans="short medium"
basedir="/home2/data/Projects/CWAS/nki/cwas"
sdir="compcor_kvoxs_fwhm08_to_kvoxs_fwhm08"
mnames="iq_age+sex+meanFD iq_age+sex+meanFD+meanGcor"

for scan in $scans; do
    echo $scan
    for mname in $mnames; do
        echo $mname
        cp ${basedir}/${scan}/${sdir}/${mname}.mdmr/cluster_correct_v05_c05/images/montage-box_clust_logp_FSIQ.png ${basedir}/scratch/${scan}_${mname}.png
    done
done

mnames="meanGcor_iq+age+sex+meanFD"
for scan in $scans; do
    echo $scan
    for mname in $mnames; do
        echo $mname
        cp ${basedir}/${scan}/${sdir}/${mname}.mdmr/cluster_correct_v05_c05/images/montage-box_clust_logp_${scan}_meanGcor.png ${basedir}/scratch/${scan}_${mname}.png
    done
done
