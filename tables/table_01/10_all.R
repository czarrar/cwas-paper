# IQ

> setwd("/home/data/Projects/CWAS/share/nki/subinfo/40_Set1_N104")
> df <- read.csv("subject_info_with_iq.csv")
> head(df)
  X        Id X.1 Age Sex Handedness orig_index nscans short medium long all
1 1 M10902157   1  36   F      Right         74      3     1      1    1   3
2 2 M10905290   5  28   M       None         65      3     1      1    1   3
3 3 M10905488   6  44   M      Right         94      3     1      1    1   3
4 4 M10905521   7  62   M      Right        146      3     1      1    1   3
5 5 M10906057   8  63   F      Right        149      3     1      1    1   3
6 6 M10906780   9  49   F      Right        108      3     1      1    1   3
  short_meanFD medium_meanFD long_meanFD VIQ PIQ FSIQ
1   0.13935629     0.3115920  0.10407771  95  96   95
2   0.11016262     0.3201844  0.24654913  95 103   99
3   0.07246874     0.1366198  0.04862486 100 102  101
4   0.10074847     0.2185981  0.07936410 125 103  117
5   0.19698303     0.5521676  0.26863382  92  90   89
6   0.06826247     0.1911339  0.24343378  94  96   94
> nrow(df)
[1] 104
> 
> table(df$Sex)
 F  M 
71 33 
> mean(df$Age)
[1] 40.27885
> range(df$Age)
[1] 18 65


# Development

> setwd("/home/data/Projects/CWAS/share/development+motion/subinfo")
> df <- read.csv("02_details_with_gcors.csv")
> head(df)
  X         id cohort sex     age time.points  tr    mean_FD meanGcor
1 1 sub0015001      1   M  9.9357         133 2.5 0.19751545  0.08577
2 2 sub0015002      1   F  7.1677         133 2.5 0.11075522  0.07473
3 3 sub0015003      1   M  9.8300         133 2.5 0.15756911  0.06668
4 4 sub0015004      1   F  7.4606         133 2.5 1.19734120  0.09215
5 5 sub0015006      3   F 21.8097         133 2.5 0.09687592  0.06467
6 6 sub0015008      1   F  8.6352         133 2.5 0.34297953  0.15847
> nrow(df)
[1] 77
> table(df$sex)
 F  M 
40 37 
> mean(df$age)
[1] 14.76806
> range(df$age)
[1]  6.7159 24.7666


# ADHD

> df <- read.csv("30_subjects_matched_combined_meanGcor.csv")
> setwd("/home/data/Projects/CWAS/share/adhd200_rerun/subinfo")
> nrow(df)
[1] 114
> table(df$diagnosis)

ADHD  TDC 
  57   57 
> mean(df$age)
[1] 12.25254
> tapply(df$age, df$diagnosis, mean)
    ADHD      TDC 
12.12298 12.38211 
> tapply(df$age, df$diagnosis, range)                                                                                
$ADHD
[1]  7.86 17.61

$TDC
[1]  7.17 17.83

> tapply(df$sex, df$diagnosis, table)                                                                                
$ADHD

Female   Male 
    22     35 

$TDC

Female   Male 
    22     35 

> table(df$sex)

Female   Male 
    44     70 
> mean(df$age)
[1] 12.25254
> range(df$age)
[1]  7.17 17.83



# L-DOPA

> setwd("/home/data/Projects/CWAS/share/ldopa/subinfo")

