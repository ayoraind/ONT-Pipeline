#!/bin/bash

FILE=${1}
#LIST=$2

#STAT=$(basename $(basename ${LIST}) .txt)
echo "Filename"$'\t'"mean_read_length"$'\t'"mean_read_quality"$'\t'"median_read_length"$'\t'"median_read_quality"$'\t'"number_of_reads"$'\t'"read_length_N50"$'\t'"STDEV_read_length"$'\t'"Total_bases"$'\t'"Q5_num"$'\t'"Q5_perc"$'\t'"Q5_mb"$'\t'"Q7_num"$'\t'"Q7_perc"$'\t'"Q7_mb"$'\t'"Q10_num"$'\t'"Q10_perc"$'\t'"Q10_mb"$'\t'"Q12_num"$'\t'"Q12_perc"$'\t'"Q12_mb"$'\t'"Q15_num"$'\t'"Q15_perc"$'\t'"Q15_mb"$'\t'"highest_mean_qscore"$'\t'"highest_mean_len"$'\t'"longest_reads_len"$'\t'"longest_reads_mean_qscore" > ${FILE}.transposed.NanoStats.txt


mean_read_length=$(cat ${FILE}.NanoStats.txt | awk 'NR == 2 {print $4}')
mean_read_quality=$(cat ${FILE}.NanoStats.txt | awk 'NR == 3 {print $4}')
median_read_length=$(cat ${FILE}.NanoStats.txt | awk 'NR == 4 {print $4}')
median_read_quality=$(cat ${FILE}.NanoStats.txt | awk 'NR == 5 {print $4}')
number_of_reads=$(cat ${FILE}.NanoStats.txt | awk 'NR == 6 {print $4}')
read_length_N50=$(cat ${FILE}.NanoStats.txt | awk 'NR == 7 {print $4}')
STDEV_read_length=$(cat ${FILE}.NanoStats.txt | awk 'NR == 8 {print $4}')
Total_bases=$(cat ${FILE}.NanoStats.txt | awk 'NR == 9 {print $3}')
#num=number, perc=percentage, mb=megabases
#Q5_num_perc_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 11 {print $2,$3,$4}')
Q5_num=$(cat ${FILE}.NanoStats.txt | awk 'NR == 11 {print $2}')
Q5_perc=$(cat ${FILE}.NanoStats.txt | awk 'NR == 11 {print $3}' | tr -d '()%')
Q5_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 11 {print $4}' | tr -d 'Mb')
#Q7_num_perc_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 12 {print $2,$3,$4}')
Q7_num=$(cat ${FILE}.NanoStats.txt | awk 'NR == 12 {print $2}')
Q7_perc=$(cat ${FILE}.NanoStats.txt | awk 'NR == 12 {print $3}' | tr -d '()%')
Q7_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 12 {print $4}' | tr -d 'Mb')
#Q10_num_perc_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 13 {print $2,$3,$4}')
Q10_num=$(cat ${FILE}.NanoStats.txt | awk 'NR == 13 {print $2}')
Q10_perc=$(cat ${FILE}.NanoStats.txt | awk 'NR == 13 {print $3}' | tr -d '()%')
Q10_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 13 {print $4}' | tr -d 'Mb')
#Q12_num_perc_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 14 {print $2,$3,$4}')
Q12_num=$(cat ${FILE}.NanoStats.txt | awk 'NR == 14 {print $2}')
Q12_perc=$(cat ${FILE}.NanoStats.txt | awk 'NR == 14 {print $3}' | tr -d '()%')
Q12_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 14 {print $4}' | tr -d 'Mb')
#Q15_num_perc_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 15 {print $2,$3,$4}')
Q15_num=$(cat ${FILE}.NanoStats.txt | awk 'NR == 15 {print $2}')
Q15_perc=$(cat ${FILE}.NanoStats.txt | awk 'NR == 15 {print $3}' | tr -d '()%')
Q15_mb=$(cat ${FILE}.NanoStats.txt | awk 'NR == 15 {print $4}' | tr -d 'Mb')
#top mean basecall quality score (qs) and read length (len)
#highest_mean_qscore_len=$(cat ${FILE}.NanoStats.txt | awk 'NR == 17 {print $2,$3}')
highest_mean_qscore=$(cat ${FILE}.NanoStats.txt | awk 'NR == 17 {print $2}')
highest_mean_len=$(cat ${FILE}.NanoStats.txt | awk 'NR == 17 {print $3}' | tr -d '()')
#longest reads and mean basecall quality score
#longest_len_qscore=$(cat ${FILE}.NanoStats.txt | awk 'NR == 23 {print $2,$3}')
longest_reads_len=$(cat ${FILE}.NanoStats.txt | awk 'NR == 23 {print $2}')
longest_reads_mean_qscore=$(cat ${FILE}.NanoStats.txt | awk 'NR == 23 {print $3}' | tr -d '()')

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" $FILE $mean_read_length $mean_read_quality $median_read_length $median_read_quality $number_of_reads $read_length_N50 $STDEV_read_length $Total_bases $Q5_num $Q5_perc $Q5_mb $Q7_num $Q7_perc $Q7_mb $Q10_num $Q10_perc $Q10_mb $Q12_num $Q12_perc $Q12_mb $Q15_num $Q15_perc $Q15_mb $highest_mean_qscore $highest_mean_len $longest_reads_len $longest_reads_mean_qscore >> ${FILE}.transposed.NanoStats.txt
# remove bam file
#rm -rf /MIGE/01_DATA/02_MAPPING/${FILE}*.{bam,bai} 
