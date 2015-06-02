#!/usr/bin/bash
# ----------------QSUB Parameters----------------- #
#PBS -k oe
#PBS -l nodes=1:ppn=2,vmem=50gb,walltime=4:00:00
#PBS -M raga.krishnakumar@ucsf.edu
#PBS -m abe
#PBS -N bamtobg
#PBS -t 1-8
# ----------------Load Modules-------------------- #
#module load perl/5.16.1
# ----------------Your Commands------------------- #
cd $PBS_O_WORKDIR
perl /N/dc2/projects/RNAMap/raga/newbed2/job.pl $PBS_ARRAYID

##raga##