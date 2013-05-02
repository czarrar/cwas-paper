### Quick prototyping here

import os, yaml
from os import path
from glob import glob

from glm_helpers import YamlReader
from glm_model import GlmModel
from glm_run import GlmRun
from process import Process


## Config with parameters
config_file = 'y_glm.yml'
config = YamlReader(config_file)
config.compile()


## Create Model/Contrasts
model = GlmModel(**config.model)
model.run() # still not spitting out the stdout in real-time
model.save()


## Special for ADHD: Create the File-Lists
from pandas import read_csv
from os import path

model_csv = read_csv(config.model['model_file'])

outfile = config.glm['infuncs1']
roi_files = model_csv.func_outdir + \
                "/func/bandpass_freqs_0.01.0.1/rois_random_k3200.nii.gz"
roi_files.to_csv(outfile, index=False, sep=" ")

outfile = config.glm['infuncs2']
func_files = model_csv.func_outdir + \
                "/func/bandpass_freqs_0.01.0.1/functional_mni_4mm.nii.gz"
func_files.to_csv(outfile, index=False, sep=" ")


## Run glm
# output directory
base_glm = path.dirname(config.data['glm_dir'])
if not path.exists(base_glm):
    os.mkdir(base_glm)
# ok now run
glm = GlmRun(**config.glm)
glm.run()


## Summarize
## Goal: To easily represent the 4D GLM results (2D matrix) as 3D (1D vector) 
##       for easy visualization and comparison

# output directory
summarize_out = config.summarize['out_dir']
if not path.exists(summarize_out):
    os.mkdir(summarize_out)

# get args
arg_order = ["regressors", "mask", "rois", "tvals", "out_dir"]
args = [ config.summarize[arg] for arg in arg_order ]
arg3 = ""
for tval_info in eval(args[3]):
    arg3 += "%s %s " % tuple(tval_info.split())
args[3] = arg3[0:-1]

# execute command
p = Process("./glm_summarize.R %s" % " ".join(args))
print p.stdout
if p.pid != 0:
    print p.stderr
    stop("glm_summarize.R failed")


## Combine GLM Summary with MDMR
from glob import glob
arg_order = ["mask", "mdmr_pvals", "glm_summary", "out_dir"]
args = [ config.dataframe[arg] for arg in arg_order ]
args[2] = " ".join(glob(args[2]))
p = Process("./glm_dataframe.R %s" % " ".join(args))
print p
if p.pid != 0:
    print p.stderr
    stop("glm_dataframe.R failed")


## Thresholded nifti maps


### ggplot


# Get summary measures
# such as similarity, range of glm, etc

# Save plot

# Run report page
