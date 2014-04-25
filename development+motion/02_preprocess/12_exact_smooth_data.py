#!/usr/bin/env python

import os, sys
from os import path as op
from pandas import read_table

# set OMP NUM THREADS to 1


####


print "\nRead in user args"

cmd  = sys.argv[0]
args = sys.argv[1:]
if len(args) != 3:
    print "usage: %s [resolution] [fwhm] [overwrite: 0 or 1]" % cmd
    sys.exit(2)

res  = int(args[0])
fwhm = int(args[1])
to_overwrite = bool(args[2])


####


print "\nProcess paths and other variables"

dirnames = lambda paths: [ op.dirname(path) for path in paths ]
joins    = lambda paths,add_path: [ op.join(path, add_path) for path in paths ]
replaces = lambda strings,find,repl: [ string.replace(find,repl) for string in strings ]

# background
basedir = "/home2/data/Projects/CWAS/share/development+motion"
subinfo = op.join(basedir, "subinfo")

# input functional paths
flist   = op.join(subinfo, "02_funcpaths_global_%imm.txt" % res)
infiles = read_table(flist, header=None).ix[:,0].tolist()
infiles = replaces(infiles, "/home/", "/home2/")

# input masks (use the non-global data's mask)
flist0   = op.join(subinfo, "02_funcpaths_%imm.txt" % res)
infiles0 = read_table(flist0, header=None).ix[:,0].tolist()
infiles0 = replaces(infiles0, "/home/", "/home2/")
maskfiles = joins(dirnames(dirnames(infiles0)), "functional_brain_mask_to_standard_%imm.nii.gz" % res)
for mf in maskfiles:
    if not op.exists(mf): raise Exception("maskfile: %s doesn't exist" % mf)

# ouput funcs
outfiles = replaces(infiles, ".nii.gz", "_fwhm%02i.nii.gz" % fwhm)
for outfile in outfiles:
    if op.exists(outfile):
        if to_overwrite:
            os.remove(outfie)
        else:
            print "outfile exists: %s" % outfile

# output functional paths
prefix    = flist.replace(".txt", "")
out_flist = "%s_fwhm%02i.txt" % (prefix, fwhm)

# save output list
outf = open(out_flist, 'w')
outf.writelines([ l + "\n" for l in outfiles ])
outf.close()


#####


print "\nRun"

for i,infile in enumerate(infiles):
    maskfile = maskfiles[i]
    outfile  = outfiles[i]
    
    cmd = "3dBlurToFWHM -input %s -mask %s -FWHM %i -prefix %s" % (infile, maskfile, fwhm, outfile)
    
    sfn   = 'qsub_scripts/exact_smooth_%imm_%02ifwhm_sub%03i.bash' % (res, fwhm, i+1)
    sfile = open(sfn, 'w')
    sfile.write("#!/usr/bash\n")
    sfile.write("echo '%s'\n" % cmd)
    sfile.write(cmd + "\n")
    sfile.close()
    
    log_file = 'qsub_logs/exact_smooth_%imm_%02ifwhm_sub%03i.log' % (res, fwhm, i+1)
    qcmd = "qsub -S /bin/bash -V -cwd -o %s -j y %s" % (log_file, sfn)
    print qcmd
    os.system(qcmd)


