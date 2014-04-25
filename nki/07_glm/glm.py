### Quick prototyping here

import os, yaml
from os import path
from glob import glob

from glm_helpers import YamlReader
from glm_model import GlmModel
from glm_run import GlmRun
from process import Process

scans = ["short", "medium"]

for scan in scans:
    ## Config with parameters
    config_file = "config_%s.yml" % scan
    config = YamlReader(config_file)
    config.compile()
    
    ## Create Model/Contrasts
    model = GlmModel(**config.model)
    model.run() # still not spitting out the stdout in real-time
    model.save()
    
    ## Run glm
    # output directory
    base_glm = path.dirname(config.data['glm_dir'])
    if not path.exists(base_glm):
        os.mkdir(base_glm)
    # ok now run
    glm = GlmRun(**config.glm)  # NOTE: this doesn't really work right now, 
    glm.run()                   #       do this step manually
    
    ## Summarize
    ## Goal: To easily represent the 4D GLM results (2D matrix) as 3D (1D vector) 
    ##       for easy visualization and comparison
    
    # output directory
    summarize_out = config.summarize['out_dir']
    if not path.exists(summarize_out):
        os.mkdir(summarize_out)
    
    # get args
    arg_order = ["regressors", "mask", "tvals", "out_dir"]
    args = [ config.summarize[arg] for arg in arg_order ]
    arg3 = ""
    for tval_info in eval(args[2]):
        arg3 += "%s %s " % tuple(tval_info.split())
    args[2] = arg3[0:-1]
    
    # execute command
    p = Process("./glm_summarize.R %s" % " ".join(args))
    print p.stdout
    if p.pid != 0:
        print p.stderr
        raise Exception("glm_summarize.R failed")   # note will fail but seems like stuff is ok

    ## Combine GLM Summary with MDMR
    from glob import glob
    arg_order = ["mask", "mdmr_zstats", "glm_summary", "out_dir"]
    args = [ config.dataframe[arg] for arg in arg_order ]
    args[2] = " ".join(glob(args[2]))
    p = Process("./glm_dataframe.R %s" % " ".join(args))
    print p
    if p.pid != 0:
        print p.stderr
        raise Exception("glm_dataframe.R failed")


## Thresholded nifti maps


### ggplot


# Get summary measures
# such as similarity, range of glm, etc

# Save plot

# Run report page
