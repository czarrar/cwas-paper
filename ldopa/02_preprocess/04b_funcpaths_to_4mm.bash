#!/bin/bash

cd /home/data/Projects/CWAS/share/ldopa/subinfo

sed s/functional_mni/functional_mni_4mm/g 02_ldopa_funcpaths.txt > 02_ldopa_funcpaths_4mm.txt
sed s/functional_mni/functional_mni_4mm/g 02_placebo_funcpaths.txt > 02_placebo_funcpaths_4mm.txt
sed s/functional_mni/functional_mni_4mm/g 02_all_funcpaths.txt > 02_all_funcpaths_4mm.txt
