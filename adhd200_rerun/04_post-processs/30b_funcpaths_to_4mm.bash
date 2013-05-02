#!/bin/bash

cd /home/data/Projects/CWAS/share/adhd200_rerun/subinfo

sed s/functional_mni/functional_mni_4mm/g 30_compcor_funcpaths.txt > 30_compcor_funcpaths_4mm.txt
sed s/functional_mni/functional_mni_4mm/g 30_global_funcpaths.txt > 30_global_funcpaths_4mm.txt
