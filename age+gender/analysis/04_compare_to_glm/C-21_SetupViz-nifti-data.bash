#!/bin/bash

"""
This script copies over the MDMR output files and into a special directory for SUMA viz

SETUP PATHS
-----------
Vicki needs to gather her resources.
She needs to find the base directory
to her MDMR results and
to her GLM results
She will want to get the sub-directory
for the distances and glm directory

SETUP OUTPUTS
-------------
Vicki then sets up camp
where she creates the output directory
and copies over the standard brain and brain mask

COMPUTE OUTPUTS
---------------
She wants to get the top 5%, 10%, & 15% of values
for the discovery and replication samples
for all the different parcellation sizes (right now there is just 3200)
for age and sex effects
for the MDMR and GLM results
"""

## SETUP PATHS

# Base Directories
base="/home2/data/Projects/CWAS/age+gender"
mbase="${base}/03_robustness/cwas"      # MDMR
gbase="${base}/04_compare_to_glm/glm"   # GLM
odir="${base}/04_compare_to_glm/nifti"  # Output

# Sub-Directories
ks="rois_random_k3200"
samples="discovery replication"
factors="age sex"


## SETUP OUTPUTS

# Create dictionary
mkdir $odir 2> /dev/null

# Copy over standard brain and brain mask
cp ${mbase}/discovery_rois_random_k3200/bg_image.nii.gz ${odir}/standard_4mm.nii.gz
cp ${mbase}/discovery_rois_random_k3200/mask2.nii.gz ${odir}/mask.nii.gz


## COMPUTE OUTPUTS

# Loop through samples
for sample in ${samples}; do
    echo "SAMPLE: ${sample}"
    
    # Loop through parcellations (currently just one)
    for k in ${ks}; do
        echo "  PARCELS: ${k}"
        
        # Raw Result Directories
        mdir="${mbase}/${sample}_${k}/age+gender_15k.mdmr" # MDMR
        sdir="${gbase}/${sample}_${k}/summary"             # GLM Summary
        
        # Loop through factors
        for factor in ${factors}; do
            echo "    FACTOR: ${k}"
            
            # Result Files
            mfile="${mdir}/fdr_logp_${factor}.nii.gz"   # MDMR
            sfile="${sdir}/uwt_${factor}.nii.gz"        # GLM Summary
            
            # Thresholds for 15%, 10%, 5%
            ### MDMR
            mthrs=( $( 3dBrickStat -non-zero -percentile 85 5 95 ${mfile} | awk '{print $2,$4,$6}' ) )
            ### GLM
            sthrs=( $( 3dBrickStat -non-zero -percentile 85 5 95 ${sfile} | awk '{print $2,$4,$6}' ) )
            
            # Outputs
            o_mfile="${odir}/${sample}_${k}_${factor}_mdmr.nii.gz"  # MDMR
            o_sfile="${odir}/${sample}_${k}_${factor}_glm.nii.gz"   # GLM Summary
            
            # Threshold and Combine
            echo "      MDMR"
            3dcalc -a ${mfile} -expr "step(a-${mthrs[0]}) + step(a-${mthrs[1]}) + step(a-${mthrs[2]})" -prefix ${o_mfile}
            echo "      GLM"
            3dcalc -a ${sfile} -expr "step(a-${sthrs[0]}) + step(a-${sthrs[1]}) + step(a-${sthrs[2]})" -prefix ${o_sfile}
            
        done
        
    done
done

