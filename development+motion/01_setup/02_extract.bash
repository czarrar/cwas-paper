cd /home2/data/Originals/POWER_2012
tar -xzvf POWER_2012_COHORT_1.001.001.LiteNIFTI.tar.gz
tar -xzvf POWER_2012_COHORT_2.001.001.LiteNIFTI.tar.gz
tar -xzvf POWER_2012_COHORT_3.001.001.LiteNIFTI.tar.gz

# put into cohort1, cohort2, cohort3 folders

# remove subjects without fMRI
rm -rf cohort1/sub0015018