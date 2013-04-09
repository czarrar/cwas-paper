#!/bin/bash

base="/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution"
network_names="visual somatomotor dorsal_attention ventral_attention limbic frontoparietal default"

for network in ${network_names}; do
    scriptfile="${base}/sge_scripts/group_mean_${network}_run05b.bash"
    outfile="${base}/sge_outs/group_mean_${network}_run05b.out"
    errfile="${base}/sge_outs/group_mean_${network}_run05b.err"
    
    echo "#!/bin/bash" > $scriptfile
    echo "cd $base" >> $scriptfile
    echo "python B-GenROIs_03b-group-mean-parcellate.py 8 $network" >> $scriptfile

    chmod +x $scriptfile
    qsub -S /bin/bash -V -cwd -o ${outfile} -e ${errfile} -pe mpi_smp 8 $scriptfile
done
