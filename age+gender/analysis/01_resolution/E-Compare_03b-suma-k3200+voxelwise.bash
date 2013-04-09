#!/bin/bash

# This script creates images for the k3200 at varying levels of threshold
thresholds="0 035 085 135 185" # divide by 10

if [[ "$#" -ne 1 ]]; then
    echo "usage: $0 lh or rh"
    exit 1
fi
hemi=$1

base="/home2/data/Projects/CWAS/age+gender/01_resolution/cwas"
cdir="${base}/combined_rois+voxelwise"
cd $cdir

# Load AFNI
afni -niml -yesplugouts &

# Setup
plugout_drive -com "SET_PBAR_ALL A.+99 1.0 Spectrum:yellow_to_red" -quit; sleep 2
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
odir="suma_images_vary_threshold"
mkdir ${odir} 2> /dev/null

if [[ "$hemi" = "lh" ]]; then
    key_med="ctrl+right"
    key_lat="ctrl+left"
elif [[ "$hemi" = "rh" ]]; then
    key_med="ctrl+left"
    key_lat="ctrl+right"
else
    zerror "hemi: ${hemi} unknown (can only be lh or rh)"
fi

template_file="fdr_*_rois-to-voxel_k*.nii.gz fdr_*_voxelwise.nii.gz"
#template_file="*_rois-to-voxel_k*.nii.gz"
#template_file="*_rois*k3200.nii.gz"
#template_file="*_voxelwise.nii.gz"
wait_time=10

overlays=$( ls -d ${template_file} | tr '\n' ' ' )
echo "PICS FOR: ${overlays}"

DriveSuma -com viewer_cont -key R; sleep 4
 
for overlay in ${overlays}; do
    for thresh in ${thresholds}; do
        prefix="${overlay%.nii.gz}"
    
        echo
        echo "Running: ${prefix}"
    
        # Set overlay in AFNI
        echo "  Loading overlay in AFNI"
        plugout_drive -com "SWITCH_FUNCTION ${overlay}" -quit; sleep 1
        plugout_drive -com "SET_THRESHOLD A.${thresh} 1" -quit; sleep 2
    
        # SUMA
        echo "  Getting pictures in SUMA"
        DriveSuma \
        -com viewer_cont -key ${key_med} \
        -com recorder_cont -save_as ${odir}/${prefix}_thr${thresh}_${hemi}_med.jpg \
        -com viewer_cont -key ${key_lat} \
        -com recorder_cont -save_as ${odir}/${prefix}_thr${thresh}_${hemi}_lat.jpg
    
        sleep ${wait_time}
    done
done
 
DriveSuma -com viewer_cont -key R; sleep 4
