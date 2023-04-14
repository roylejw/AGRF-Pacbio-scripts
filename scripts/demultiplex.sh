#!/bin/sh

### Housekeeping variables - no need to change ###
storage="/mnt/efs/fs2/output"
resources="/home/ubuntu/AGRF-Pacbio-scripts/resources"

# Source conda to start lima
source ~/miniconda3/etc/profile.d/conda.sh
cd ~

### Copy barcodes in and clear weird windows chars from csv ###

dos2unix barcode-sample-"$barcode".csv
mv barcode-sample-"$barcode".csv barcode-sample.csv
cp "$resources"/"$barcode".fasta .

### Run lima ###

echo "Running Lima (and converting bam to fastq if required)."

if [ "$barcode" == "isoseq" ];
	then
		conda activate lima
		lima --isoseq --peek-guess --split-named "$filename"."$format" "$barcode".fasta demux."$format"
	else
	
	if [ "$format" == bam ]; then
		conda activate pbtools
		pbindex "$filename"."$format"
		bam2fastq -u -o "$filename" "$filename"."$format"
		format=fastq
		conda deactivate
	fi

	if [ "$format" == fastq.gz ]; then
		gunzip "$filename"."$format"
		format=fastq
	fi
	conda activate lima
	lima --hifi-preset ASYMMETRIC --split-named --output-missing-pairs "$filename"."$format" "$barcode".fasta demux."$format"
fi 

### Create directory, format and rename demultiplexed samples ###

if [ ! -d "$storage"/"$outname"/Demultiplexed ]; then
	mkdir "$storage"/"$outname"
	mkdir "$storage"/"$outname"/Demultiplexed
fi

mkdir temp
mv demux.bc* temp/.
cd temp
cp ../barcode-sample.csv .
rename 's/demux.bc/bc/' *

sed 's/"//g' barcode-sample.csv | while IFS=, read orig new; do mv "$orig"."$format" "$new"."$format"; done
cp ../demux.lima.summary "$storage"/"$outname"/Demultiplexed/.
cp *."$format" "$storage"/"$outname"/Demultiplexed/.
