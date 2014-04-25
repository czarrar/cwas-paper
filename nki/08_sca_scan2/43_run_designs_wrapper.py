#!/usr/bin/env python

import os, sys
from os import path as op

nrois   = 100
scans   = ["short", "medium", "long"]
nscans  = len(scans)

for si in range(nscans):
    print "scans %i" % si
    for ri in range(nrois):
        print "...rois %i" % ri
        
        log_file  = op.join("qsub_logs", "%s_run_designs_scan2_roi_n%02i.log" % (scans[si], ri+1))
        
        sfn   = 'qsub_scripts/%s_run_designs_scan2_roi_n%02i.bash' % (scans[si], ri+1)
        sfile = open(sfn, 'w')
        sfile.write("#!/usr/bash\n")
        sfile.write("cd /home2/data/Projects/CWAS/share/nki/08_sca_scan2\n")
        sfile.write("./42_run_designs.py %i %i 1\n" % (si+1, ri+1))
        sfile.close()
        
        qcmd = "qsub -S /bin/bash -V -cwd -o %s -j y %s" % (log_file, sfn)
        print qcmd
        os.system(qcmd)
        
        