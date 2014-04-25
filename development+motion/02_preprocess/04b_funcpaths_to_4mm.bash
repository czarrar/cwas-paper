#!/bin/bash

cd /home/data/Projects/CWAS/share/development+motion/subinfo

sed s/functional_mni/functional_mni_4mm/g 02_funcpaths.txt > 02_funcpaths_4mm.txt
sed s/functional_mni/functional_mni_4mm/g 02_funcpaths_global.txt > 02_funcpaths_global_4mm.txt
