#!/usr/bin/env python

# Want to output grp, mat, and con files

import os, sys
import numpy as np
from os import path as op
from pandas import read_csv

####


if len(sys.argv) != 2:
    print "usage: %s [1 (short) | 2 (medium) | 3 (long)]" % sys.argv[0]
    sys.exit(2)
i = int(sys.argv[1]) - 1


####


scans   = ["short", "medium", "long"]
setxs   = ["40_Set1_N104", "40_Set1_N104", "40_Set2_N92"]
scan    = scans[i]
setx    = setxs[i]

base        = "/home2/data/Projects/CWAS"
subdir      = op.join(base, "share/nki/subinfo")
setdir      = op.join(subdir, setx)
modelfile   = op.join(setdir, "subject_info_with_iq_and_gcors.csv")

odir    = op.join(setdir, "sca_fsl")
if not op.exists(odir):
    os.mkdir(odir)


####

model   = read_csv(modelfile)
nsubs   = model.shape[0]

center      = lambda x: x - x.mean()
regressors  = np.array([
    np.ones(nsubs), 
    center(model.FSIQ), 
    center(model.Age), 
    1*(model.Sex == 'M') - 1*(model.Sex == 'F'), 
    center(model["%s_meanFD" % scan])
]).T

nvars   = regressors.shape[1]

###
# Group File
###

print "grp"

# /NumWaves	1
# /NumPoints	10
# 
# /Matrix
# 1
# 1
# 1
# 1
# 1
# 1
# 1
# 1
# 1
# 1

grp_file = open(op.join(odir, "%s.grp" % scan), 'w')
grp_file.write('/NumWaves 1\n')
grp_file.write('/NumPoints %i\n' % nsubs)
grp_file.write('\n')
grp_file.write('/Matrix\n')
grp_file.writelines([ '1\n' for i in range(nsubs) ])
grp_file.close()


###
# Mat File
###

print "mat"

# /NumWaves	5
# /NumPoints	10
# /PPheights		1.000000e+00	1.000000e+00	1.000000e+00	6.900000e-01	2.000000e+00
# 
# /Matrix
# 1.000000e+00	0.000000e+00	0.000000e+00	1.200000e-01	0.000000e+00	
# 1.000000e+00	0.000000e+00	0.000000e+00	2.300000e-01	0.000000e+00	
# 1.000000e+00	1.000000e+00	0.000000e+00	3.500000e-01	0.000000e+00	
# 1.000000e+00	1.000000e+00	-1.000000e+00	0.000000e+00	0.000000e+00	
# 1.000000e+00	0.000000e+00	-1.000000e+00	-3.400000e-01	1.000000e+00	
# 1.000000e+00	0.000000e+00	0.000000e+00	-2.100000e-01	-1.000000e+00	
# 1.000000e+00	0.000000e+00	0.000000e+00	-1.100000e-01	0.000000e+00	
# 1.000000e+00	0.000000e+00	0.000000e+00	0.000000e+00	0.000000e+00	
# 1.000000e+00	0.000000e+00	0.000000e+00	0.000000e+00	0.000000e+00	
# 1.000000e+00	0.000000e+00	0.000000e+00	0.000000e+00	0.000000e+00	

ppheights = np.apply_along_axis(lambda x: np.max(x) - np.min(x), 0, regressors)
ppheights[0] = 1
list2fsl  = lambda xs: "\t".join([ "%.7e" % x for x in xs ])

mat_file = open(op.join(odir, "%s.mat" % scan), 'w')
mat_file.write('/NumWaves\t%i\n' % nvars)
mat_file.write('/NumPoints\t%i\n' % nsubs)
mat_file.write('\n')
mat_file.write('/PPheights\t%s\n' % list2fsl(ppheights))
mat_file.write('\n')
mat_file.write('/Matrix\n')
for i in range(nsubs):
    mat_file.write(list2fsl(regressors[i,:]) + "\n")
mat_file.close()


###
# Con File
###

print "con"

# /ContrastName1	 "Age+"
# /ContrastName2	 "Age-"
# /ContrastName3	 "Global+"
# /ContrastName4	 "Global-"
# /NumWaves	5
# /NumContrasts	4
# /PPheights		1.750559e+00	1.750559e+00	8.933097e-01	8.933097e-01
# /RequiredEffect		19.475	19.475	27.380	27.380
# 
# /Matrix
# 1.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00 
# -1.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00 
# 0.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00 1.000000e+00 
# 0.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00 -1.000000e+00 

con_file = open(op.join(odir, "%s.con" % scan), 'w')
con_file.write('/ContrastName1\t"IQ+"\n')
con_file.write('/ContrastName2\t"IQ-"\n')
con_file.write('/NumWaves\t%i\n' % nvars)
con_file.write('/NumContrasts\t%i\n' % 2)
con_file.write('/PPheights\t1.750559e+00	1.750559e+00\n')
con_file.write('/RequiredEffect\t10\t19.475	19.475\n')
con_file.write('\n')
con_file.write('/Matrix\n')
con_file.write('0.000000e+00 1.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00\n')
con_file.write('0.000000e+00 -1.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00\n')
con_file.write('0.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00\n')
con_file.write('0.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00 0.000000e+00\n')
con_file.close()
