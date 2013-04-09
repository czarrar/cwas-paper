# Overview

In the 'resolution' analyses, we will look at the difference between using ROIs of different sizes versus voxelwise maps on CWAS results. We will only be looking at subjects from the Rockland sample with an equal number of males and females with a total N of 102.


## Setup

**See A-Setup_01-gather-subjects.R**. We first collect the subjects for the Rockland sample based on the complete discovery and replication sample in the age/gender analysis. We ensured an equal number of males and females who were age-matched, and this led to a total N of 102 participants.

**See A-Setup_02-generate-mask.R**. We simply get the overlap across all the functional brain masks for participants.


## Generate ROIs

I will generate the ROIs as subsets of the 7 network parcellations from the Yeo paper.

### Yeo Large-Scale Brain Networks

**See B-GenROIs_01-yeo-complete.R.**

Since not all the voxels in my group brain mask are specified in the Yeo 7 Network parcellation, I ran a simple script to define the network membership of those voxels. The script simply examined the correlation of each undefined voxel's time-series with the average time-series from each of the 7 networks. The voxel's network membership was then the network with which it had the highest correlation.

### Craddock Spatially Constrained Parcellation

**Subject-Level Connectivity using B-GenROIs_02*:** We calculated the spatial connectivity for each subject.

**Group-Mean Parcellation using B-GenROIs_03*:** We calculated the mean connectivity across all participants and then parcellated each of the networks into ROIs of varying sizes.

**Save Parcellations using B-GenROIs_04-save-parcellations.py:** Here, we simply save the parcellations into nifti format.

add B-GenROIs_05_equalized_parcellations.R to here.

add script that combines the ROIs together into 2 types

## TODO

- Run the MDMR for voxelwise analysis
- Gather the ROIs for computing CWAS
    - 5,10...
    - each network
    
