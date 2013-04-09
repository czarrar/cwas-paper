#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "usage: $0 lh or rh"
    exit 1
fi
hemi=$1

base="/home2/data/Projects/CWAS/age+gender/03_robustness"
cdir="${base}/viz_cwas"
cd $cdir

# Load AFNI
afni -niml -yesplugouts &

# Setup
plugout_drive -com "SET_PBAR_NUMBER A.4" -quit; sleep 2
plugout_drive -com "SET_PBAR_ALL A.+4 1.0=green 0.75=orange 0.5=lt-blue1 0.25=none" -quit; sleep 2
plugout_drive -com "SET_THRESHOLD A.0 0" -quit; sleep 2

# Load SUMA
suma -spec /home2/data/PublicProgram/suma_template/MNI152_${hemi}_pialinf.spec -sv MNI152_Anat.nii -niml &
sleep 20

DriveSuma -com viewer_cont -key F3; sleep 2
#DriveSuma -com viewer_cont -key F1; sleep 2
DriveSuma -com viewer_cont -key F6; sleep 2
DriveSuma -com viewer_cont -key b; sleep 2
DriveSuma -com viewer_cont -key t; sleep 2
DriveSuma -com viewer_cont -key:r17:s0.2 period; sleep 2

echo 'ready?'
read

# Save Images
mkdir suma_images 2> /dev/null

if [[ "$hemi" = "lh" ]]; then
    key_med="ctrl+right"
    key_lat="ctrl+left"
elif [[ "$hemi" = "rh" ]]; then
    key_med="ctrl+left"
    key_lat="ctrl+right"
else
    zerror "hemi: ${hemi} unknown (can only be lh or rh)"
fi
 
template_file="fdr_*_overlap_*.nii.gz"
wait_time=10

overlays=$( ls -d ${template_file} | tr '\n' ' ' )
echo "PICS FOR: ${overlays}"

DriveSuma -com viewer_cont -key R; sleep 4
 
for overlay in ${overlays}; do
    prefix="${overlay%.nii.gz}"
    
    echo
    echo "Running: ${prefix}"
    
    # Set overlay in AFNI
    echo "  Loading overlay in AFNI"
    plugout_drive -com "SWITCH_FUNCTION ${overlay}" -quit; sleep 1
    
    # SUMA
    echo "  Getting pictures in SUMA"
    DriveSuma \
    -com viewer_cont -key ${key_med} \
    -com recorder_cont -save_as suma_images/${prefix}_${hemi}_med.jpg \
    -com viewer_cont -key ${key_lat} \
    -com recorder_cont -save_as suma_images/${prefix}_${hemi}_lat.jpg
    
    sleep ${wait_time}
done
 
DriveSuma -com viewer_cont -key R; sleep 4
