#!/bin/bash

cd /home/data/Projects/CWAS/share/age+gender/subinfo

sed s/functional_mni/functional_mni_4mm/g 04_discovery_funcpaths.txt > 04_discovery_funcpaths_4mm.txt
sed s/functional_mni/functional_mni_4mm/g 04_replication_funcpaths.txt > 04_replication_funcpaths_4mm.txt
sed s/functional_mni/functional_mni_4mm/g 04_all_funcpaths.txt > 04_all_funcpaths_4mm.txt

