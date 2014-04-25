#!/usr/bin/env python

import os, sys
from os import path as op
from pandas import read_table

# set OMP NUM THREADS to 1


####


print "\nRead in user args"

cmd  = sys.argv[0]
args = sys.argv[1:]
if len(args) != 2:
    print "usage: %s [new resolution] (overwrite: 0 or 1)" % cmd
    sys.exit(2)

res  = int(args[0])
to_overwrite = bool(args[1])


####


print "\nProcess paths and other variables"

dirnames = lambda paths: [ op.dirname(path) for path in paths ]
joins    = lambda paths,add_path: [ op.join(path, add_path) for path in paths ]
replaces = lambda strings,find,repl: [ string.replace(find,repl) for string in strings ]

# 0. background
basedir = "/home2/data/Projects/CWAS/share/development+motion"
subinfo = op.join(basedir, "subinfo")

# 1. input functional paths
infiles = read_table(op.join(subinfo, "02_funcpaths_global.txt"), header=None).ix[:,0].tolist()
infiles = replaces(infiles, "/home/", "/home2/")

# 2. 4mm resolution brain (i.e., the master)
stdfile = "/home2/data/PublicProgram/fsl-4.1.9/data/standard/MNI152_T1_%imm_brain.nii.gz" % res

# 3. output files
outfiles = joins(dirnames(infiles), "functional_mni_%imm.nii.gz" % res)
for outfile in outfiles:
    if op.exists(outfile):
        if to_overwrite:
            os.remove(outfie)
        else:
            print "outfile exists: %s" % outfile


#####


print "\nRun"

for i,infile in enumerate(infiles):
    outfile = outfiles[i]
    cmd = "3dresample -inset %s -master %s -rmode Linear -prefix %s" % (infile, stdfile, outfile)
    
    sfn   = 'qsub_scripts/subsample_%imm_sub%03i.bash' % (res, i+1)
    sfile = open(sfn, 'w')
    sfile.write("#!/usr/bash\n")
    sfile.write("echo '%s'\n" % cmd)
    sfile.write(cmd + "\n")
    sfile.close()
    
    log_file = 'qsub_logs/subsample_%imm_sub%03i.log' % (res, i+1)
    qcmd = "qsub -S /bin/bash -V -cwd -o %s -j y %s" % (log_file, sfn)
    print qcmd
    os.system(qcmd)


