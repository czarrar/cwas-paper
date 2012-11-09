#!/usr/bin/env python

from glob import glob
from os import path
from pandas import *
import os, re

###
# Read in subject lists
###

# Directories with CPAC_subject_list.py
list_dirs = glob("/home2/data/Projects/*/scripts/02_PreProc")
list_dirs.append("/home2/data/Projects/Rockland/scripts/02_PreProc/rerun")

# Subjects to exclude when reading in subject lists
## this subject id was used twice with the same scan name
bad_subs = [ "sub68050" ]
## these subjects had corrupted rest scans
bad_subs.extend(["0000003","0020005","0020007","0020016","0020026","0020027","0020044"])

# Creating a long list of all the subject lists
curdir = os.getcwd()
sublist = []
for list_dir in list_dirs:
    os.chdir(list_dir)
    import CPAC_subject_list
    reload(CPAC_subject_list)
    rawlist = CPAC_subject_list.subjects_list
    filtlist  = [ x for x in rawlist if x['Subject_id'] not in bad_subs ]
    sublist.extend(filtlist)
os.chdir(curdir)


###
# Create data frames with subject and scan details
###

# regex for extracting site and subject from the input file paths in sublist
fcon_re = re.compile("Originals/FCon1000/raw/(?P<site>\w+)/(?P<subject>\w+)")
other_re = re.compile("Originals/(?P<site>\w+)/raw/(?P<subject>\w+)")

# output directory paths
strategy = "linear1.wm1.motion1.csf1_CSF_0.98_GM_0.7_WM_0.98"
anat_template = "/home2/data/PreProc/%s/sym_links/pipeline_0/%s/%s_%s/scan"
func_template = "/home2/data/PreProc/%s/sym_links/pipeline_0/%s/%s_%s/scan_%s"

# initialize the dict objects that will become data frames
cols = ['site', 'orig_id', 'id', 'func_run', 'anat_infile', 'func_infile', 'anat_outdir', 'func_outdir']
d = { x : [] for x in cols }

for details in sublist:
    run_num = 0
    for run_name, run_filename in details['rest'].iteritems():
        run_num += 1
        if run_filename.find('FCon1000') != -1:
            search = fcon_re.search(run_filename).groupdict()
            anat_outdir = anat_template % ('FCon1000', strategy, search['subject'], details['Unique_id'])
            func_outdir = func_template % ('FCon1000', strategy, search['subject'], details['Unique_id'], run_name)
        else:
            search = other_re.search(run_filename).groupdict()
            anat_outdir = anat_template % (search['site'], strategy, search['subject'], details['Unique_id'])
            func_outdir = func_template % (search['site'], strategy, search['subject'], details['Unique_id'], run_name)
        d['site'].append(search['site'])
        d['orig_id'].append(search['subject'])
        d['id'].append(search['site'] + "_" + search['subject'])
        d['func_run'].append(run_num)
        d['anat_infile'].append(details['anat'])
        d['func_infile'].append(run_filename)
        d['anat_outdir'].append(anat_outdir)
        d['func_outdir'].append(func_outdir)

# convert to data-frame
df = DataFrame(d, columns=cols)

# check that main output file exists (then should be all good)
bad_ids = []
for i,row in df.T.iteritems():
    fname = path.join(row['func_outdir'], 'func/bandpass_freqs_0.01.0.1/functional_mni.nii.gz')
    if not path.exists(fname):
        print 'Missing path for %s' % row['id']
        bad_ids.append(i)
    elif not path.exists(path.realpath(fname)):
        print 'Missing real path for %s' % row['id']
        bad_ids.append(i)

# save
ofname = "/home2/data/Projects/CWAS/share/subinfo/01_paths.csv"
df.to_csv(ofname)
