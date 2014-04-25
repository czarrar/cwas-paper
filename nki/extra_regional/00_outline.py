#!/usr/bin/env python

"""
Here we will outline the analysis of regional connectivity variation with IQ.
I need to do the following steps:

1. Load the 800 parcellation units and all the subjects voxelwise functional data
2. Loop through each parcellation unit and do the following:
3. Compute all the possible correlations within the parcel for each participant
4. Compute the distance between participants for the vector of all possible within parcel correlations
5. Compute MDMR
6. After having all the data, then transform to voxelwise and save
"""
