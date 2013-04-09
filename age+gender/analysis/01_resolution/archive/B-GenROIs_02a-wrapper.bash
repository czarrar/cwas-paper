#!/bin/bash

base="/home2/data/Projects/CWAS/share/age+gender/analysis/01_resolution"
funcpaths=( $( cat z_funcpaths.txt | tr '\n' ' ' ) )

#for (( i = 0; i < ${#funcpaths[@]}; i++ )); do
for (( i = 1; i < ${#funcpaths[@]}; i++ )); do
    scriptfile="${base}/sge_scripts/sid${i}_run04b.bash"
    outfile="${base}/sge_outs/sid${i}_run04b.out"
    errfile="${base}/sge_outs/sid${i}_run04b.err"
    funcpath=${funcpaths[$i]}
    
    echo "#!/bin/bash" > $scriptfile
    echo "cd $base" >> $scriptfile
    echo "python B-GenROIs_02b-subject-spatial-corr.py 4 $i $funcpath" >> $scriptfile

    chmod +x $scriptfile
    qsub -S /bin/bash -V -cwd -o ${outfile} -e ${errfile} -pe mpi_smp 4 $scriptfile
done
