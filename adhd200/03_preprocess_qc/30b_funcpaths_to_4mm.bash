#!/bin/bash

cd /home/data/Projects/CWAS/share/adhd200/subinfo

sed s/functional_mni/functional_mni_4mm/g 04a_compcor_funcpaths.txt > 04a_compcor_funcpaths_4mm.txt
sed s/functional_mni/functional_mni_4mm/g 04b_global_funcpaths.txt > 04b_global_funcpaths_4mm.txt
