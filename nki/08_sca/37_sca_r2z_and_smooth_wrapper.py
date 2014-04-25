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
    print "usage: %s [1 | 2 | 3] [fwhm]" % cmd
    print "note: 1=short, 2=medium, 3=long"
    sys.exit(2)

i    = int(args[0]) - 1
fwhm = int(args[1])

scans = ["short", "medium", "long"]
sets  = ["40_Set1_N104", "40_Set1_N104", "40_Set2_N92"]

scan  = scans[i]
setx  = sets[i]


#####


print "\nSet paths/settings"

strategy = "compcor"

basedir   = "/home2/data/Projects/CWAS"
subdir    = op.join(basedir, "share/nki/subinfo", setx)
func_list = op.join(subdir, "%s_%s_funcpaths.txt" % (scan, strategy))
ts_list   = op.join(subdir, "%s_%s_ts_peaks100_2mm.txt" % (scan, strategy))
sca_list  = op.join(subdir, "%s_%s_sca_peaks100_2mm.txt" % (scan, strategy))


####


print "\nRead input filenames and create/save output filenames"

dirnames = lambda paths: [ op.dirname(path) for path in paths ]
joins    = lambda paths,add_path: [ op.join(path, add_path) for path in paths ]

func_files  = read_table(func_list, header=None).ix[:,0].tolist()
ts_files    = read_table(ts_list).ix[:,0].tolist()
func_masks  = joins(dirnames(dirnames(func_files)), "functional_brain_mask_to_standard.nii.gz")
sca_dirs    = joins(dirnames(func_files), "sca")
sca_files   = joins(sca_dirs, "peaks100_2mm.nii.gz")
nsubjects   = len(func_files)

for func_mask in func_masks:
    if not op.exists(func_mask):
        print "ERROR: not all func masks exist"
        sys.exit(2)


####


for i in range(nsubjects):
    print "subject #%i" % (i+1)
    
    func_mask = func_masks[i]
    sca_file  = sca_files[i]
    log_file  = op.join(op.dirname(sca_file), "peaks100_r2z_and_smooth.log")
    
    if not op.exists(func_mask) or not op.exists(sca_file):
        print "...input doesn't exist"
        continue
    
    cmd = "./36_sca_r2z_and_smooth.py %s %s %s" % (sca_file, func_mask, fwhm)
    
    sfn   = 'qsub_scripts/%s_sca_r2z_and_smooth_sub%03i.bash' % (scan, i+1)
    sfile = open(sfn, 'w')
    sfile.write("#!/usr/bash\n")
    sfile.write(cmd + "\n")
    sfile.close()
    
    qcmd = "qsub -S /bin/bash -V -cwd -o %s -j y %s" % (log_file, sfn)
    print qcmd
    os.system(qcmd)


####
