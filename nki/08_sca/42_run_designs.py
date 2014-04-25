#!/usr/bin/env python

import os, sys
from os import path as op
from pandas import read_table

import nipype.pipeline.engine as pe
import nipype.interfaces.utility as util
import nipype.interfaces.io as nio
from CPAC.group_analysis import create_group_analysis


####


if len(sys.argv) != 4:
    print "usage: %s [1 (short) | 2 (medium) | 3 (long)] roi-num num-cores" % sys.argv[0]
    sys.exit(2)
i       = int(sys.argv[1]) - 1
roi     = int(sys.argv[2])
ncores  = int(sys.argv[3])


####


strategy = "compcor"

scans   = ["short", "medium", "long"]
setxs   = ["40_Set1_N104", "40_Set1_N104", "40_Set2_N92"]
scan    = scans[i]
setx    = setxs[i]

base        = "/home2/data/Projects/CWAS"
subdir      = op.join(base, "share/nki/subinfo")
setdir      = op.join(subdir, setx)

func_list   = op.join(setdir, "%s_%s_funcpaths.txt" % (scan, strategy))

grpfile     = op.join(setdir, "sca_fsl", "%s.grp" % scan)
matfile     = op.join(setdir, "sca_fsl", "%s.mat" % scan)
confile     = op.join(setdir, "sca_fsl", "%s.con" % scan)

wdir        = op.join(base, "nki/sca/%s_%s_working" % (scan, strategy))
odir        = op.join(base, "nki/sca/%s_%s_sink" % (scan, strategy))
if not op.exists(wdir): os.mkdir(wdir)
if not op.exists(odir): os.mkdir(odir)


####


dirnames    = lambda paths: [ op.dirname(path) for path in paths ]
joins       = lambda paths,add_path: [ op.join(path, add_path) for path in paths ]

func_files  = read_table(func_list, header=None).ix[:,0].tolist()
sca_dirs    = joins(dirnames(func_files), "sca/fwhm_08")
sca_files   = joins(sca_dirs, "smoothed_zscore_peaks100_2mm.nii_roi_n%02i.nii.gz" % roi)
nsubjects   = len(func_files)

if not op.exists(sca_files[0]): raise Exception("SCA files doesn't exist")


####


zThreshold = 1.96
pThreshold = 0.05
FSLDIR     = os.environ['FSLDIR']

gpa_wf = create_group_analysis(False, "gp_analysis_compcor")
gpa_wf.base_directory = odir

gpa_wf.inputs.inputspec.zmap_files  = sca_files
gpa_wf.inputs.inputspec.z_threshold = zThreshold
gpa_wf.inputs.inputspec.p_threshold = pThreshold
gpa_wf.inputs.inputspec.parameters  = (FSLDIR, 'MNI152')
gpa_wf.inputs.inputspec.mat_file    = matfile
gpa_wf.inputs.inputspec.con_file    = confile
gpa_wf.inputs.inputspec.grp_file    = grpfile


####

ds = pe.Node(nio.DataSink(), name='gpa_sink')
ds.inputs.base_directory = op.join(odir, "roi_n%02i" % roi)
ds.inputs.container = ''
ds.inputs.regexp_substitutions = [(r'(?<=rendered)(.)*[/]','/'),
                                  (r'(?<=model_files)(.)*[/]','/'),
                                  (r'(?<=merged)(.)*[/]','/'),
                                  (r'(?<=stats/clusterMap)(.)*[/]','/'),
                                  (r'(?<=stats/unthreshold)(.)*[/]','/'),
                                  (r'(?<=stats/threshold)(.)*[/]','/'),
                                  (r'_cluster(.)*[/]',''),
                                  (r'_slicer(.)*[/]',''),
                                  (r'_overlay(.)*[/]','')]


####

wf = pe.Workflow(name = 'sca_group_analysis_roi_n%02i' % roi)
wf.base_dir = wdir  # working directory

wf.connect(gpa_wf, 'outputspec.merged',
           ds, 'merged')
wf.connect(gpa_wf, 'outputspec.zstats',
           ds, 'stats.unthreshold')
wf.connect(gpa_wf, 'outputspec.zfstats',
           ds,'stats.unthreshold.@01')
wf.connect(gpa_wf, 'outputspec.fstats',
           ds,'stats.unthreshold.@02')
wf.connect(gpa_wf, 'outputspec.cluster_threshold_zf',
           ds, 'stats.threshold')
wf.connect(gpa_wf, 'outputspec.cluster_index_zf',
           ds,'stats.clusterMap')
wf.connect(gpa_wf, 'outputspec.cluster_localmax_txt_zf',
           ds, 'stats.clusterMap.@01')
wf.connect(gpa_wf, 'outputspec.overlay_threshold_zf',
           ds, 'rendered')
wf.connect(gpa_wf, 'outputspec.rendered_image_zf',
           ds, 'rendered.@01')   
wf.connect(gpa_wf, 'outputspec.cluster_threshold',
           ds,  'stats.threshold.@01')
wf.connect(gpa_wf, 'outputspec.cluster_index',
           ds, 'stats.clusterMap.@02')
wf.connect(gpa_wf, 'outputspec.cluster_localmax_txt',
           ds, 'stats.clusterMap.@03')
wf.connect(gpa_wf, 'outputspec.overlay_threshold',
           ds, 'rendered.@02')
wf.connect(gpa_wf, 'outputspec.rendered_image',
           ds, 'rendered.@03')


wf.run(plugin='MultiProc', plugin_args={'n_procs': ncores})

####

