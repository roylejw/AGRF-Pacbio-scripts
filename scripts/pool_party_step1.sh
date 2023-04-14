#!/bin/sh

echo "Script by Jack Royle, AGRF. Please email jack.royle@agrf.org.au if any issues."
source ~/miniconda3/etc/profile.d/conda.sh


script_start=`date +%M`

if [ "$verify" == "verify" ]; then
	if [ -d /mnt/efs/fs2/pool_party/"$run_number" ]; then
		echo "Run folder exists."
	elif [ ! -d /mnt/efs/fs2/pool_party/"$run_number" ]; then
		echo "Error - run folder not present."
		echo "Verification failed."
		exit 1
	fi

	if [ -e /mnt/efs/fs2/pool_party/"$run_number"/"$filename"."$format" ]; then
		echo "CCS file exists."
	elif [ ! -e /mnt/efs/fs2/pool_party/"$run_number"/"$filename"."$format" ]; then
		echo "Error - CCS file not present."
		echo "Verification failed."
		exit 1
	fi

	if [ -e /mnt/efs/fs2/pool_party/"$run_number"/contracts.txt ]; then
		echo "List of contracts exists."
	elif [ ! -e /mnt/efs/fs2/pool_party/"$run_number"/contracts.txt ]; then
		echo "Error - contract list not present."
		echo "Verification failed."
		exit 1
	fi

	if [ -e /mnt/efs/fs2/pool_party/"$run_number"/details.tsv ]; then
		echo "Details file exists."
	elif [ ! -e /mnt/efs/fs2/pool_party/"$run_number"/details.tsv ]; then
		echo "Error - details tsv not present."
		echo "Verification failed."
		exit 1
	fi
	exit 1
fi

	cd /mnt/efs/fs2/pool_party/"$run_number"
	echo "Dos2Unix'ing the input files."
	dos2unix contracts.txt
	dos2unix details.tsv

	while read client || [[ $client ]]; do
		echo "Setting up "$client". Time started is" && date
		

		### Housekeeping - no need to change ###
		EFS="/mnt/efs/fs2/pool_party"
		PC=PC
		NC=NC
		TMPDIR="/mnt/efs/fs1/temp"

		### List of variables required to run this ###
		# File name of CCS = filename
		# Format of CCS = format (bam, fastq, zipped bam)
		# Pool party run folder = run_number
		# CAGRF code = client


		# Copy in everything required
		cd "$TMPDIR"
		mkdir "$client"
		cd "$client"

		cp "$EFS"/"$run_number"/contracts.txt .
		cp "$EFS"/"$run_number"/details.tsv .
		cp "$EFS"/../../fs1/resources/16S.fasta .
		cp "$EFS"/../../fs1/resources/lima_headers_only.csv .
		cp "$EFS"/../../fs1/resources/sample_headers_only.tsv .
		cp "$EFS"/../../fs1/resources/metadata_headers_only.tsv .

		# Check and remove spaces from client submitted sample names
		mv details.tsv details2.tsv
		awk -F "\t" '{gsub(/ /,"",$2); print}' OFS="\t" details2.tsv > details.tsv
		rm details2.tsv

		# Make client project directory in EFS

		if [ ! -f "$EFS"/"$run_number"/"$client"/demux_complete ]; then
			mkdir "$EFS"/"$run_number"/"$client"
		fi

		# Create Lima 16S barcoding csv

		awk -v client="$client" -F "\t" -vOFS="," '$3~client{print $1,$2}' details.tsv > barcode-sample.csv
		awk -v PC="$PC" -F "\t" -vOFS="," '$3~PC{print $1,$2}' details.tsv > barcode-sample-pc.csv
		awk -v NC="$NC" -F "\t" -vOFS="," '$3~NC{print $1,$2}' details.tsv > barcode-sample-nc.csv
		cat lima_headers_only.csv barcode-sample.csv barcode-sample-pc.csv barcode-sample-nc.csv > barcode-sample-16S.csv
		#cat lima_headers_only.csv barcode-sample.csv > barcode-sample-16S.csv
		rm barcode-sample.csv
		rm barcode-sample-pc.csv
		rm barcode-sample-nc.csv
		rm lima_headers_only.csv

		if [ ! -f "$EFS"/"$run_number"/"$client"/demux_complete ]; then

			### Run lima ###

			if [ "$format" == bam ]; then
				if [ ! -f "$EFS"/"$run_number"/"$filename"."$format".pbi ]; then
					echo "Indexing bam file."
					cd "$EFS"/"$run_number"
					conda activate pbtools
					pbindex "$filename"."$format"
					cd "$TMPDIR"/"$client"
					conda deactivate
				fi
				if [ ! -f "$EFS"/"$run_number"/"$filename".fastq ]; then
					echo "Converting Bam to Fastq."
					cd "$EFS"/"$run_number"
					conda activate pbtools
					bam2fastq -u -o "$filename" "$filename"."$format"
					format=fastq
					conda deactivate
					cd "$TMPDIR"/"$client"
				fi
			fi

			if [ "$format" == fastq.gz ]; then
				cd "$EFS"/"$run_number"
				if [ ! -f "$EFS"/"$run_number"/"$filename".fastq ]; then
					gunzip "$filename"."$format"
					format=fastq
				fi
				cd "$TMPDIR"/"$client"
			fi
			
			conda activate lima
			format=fastq
			echo "Running Lima - started at" && date
			start=`date +%M`
			lima -j 6 --hifi-preset ASYMMETRIC --biosample-csv barcode-sample-16S.csv --split-named --output-missing-pairs "$EFS"/"$run_number"/"$filename"."$format" 16S.fasta demux."$format" 
			end=`date +%M`
			runtime=$((end-start))
			echo "Finished Lima, time taken was: "$runtime""
			
			### Create directory, format and rename demultiplexed samples ###
			echo "Reformatting demultiplexed samples and creating metadata files."
			
			if [ ! -d "$EFS"/"$run_number"/"$client"/Demultiplexed ]; then
				mkdir "$EFS"/"$run_number"/"$client"/Demultiplexed
			fi

			mkdir temp
			mv demux.bc* temp/.
			cd temp
			cp ../barcode-sample-16S.csv .
			rename 's/demux.bc/bc/' *

			sed 's/"//g' barcode-sample-16S.csv | while IFS=, read orig new; do mv "$orig"."$format" "$new"."$format"; done
			
			# find and remove spaces in file names
			for file in *\ *; do
				new_file=${file// /}
				mv "$file" "$new_file"
			done
			
			cp ../demux.lima.summary "$EFS"/"$run_number"/"$client"/Demultiplexed/.
			cp *."$format" "$EFS"/"$run_number"/"$client"/Demultiplexed/.
			touch "$EFS"/"$run_number"/"$client"/demux_complete

			### Housekeeping just in case ###

			cd "$TMPDIR"/"$client"
			conda deactivate


			# Metadata and sample tsv creation

			awk -v client="$client" -F "\t" -vOFS='\t' '$3~client{print $2,$4,$5}' details.tsv > metadata_temp.tsv
			awk -F "\t" -vOFS='\t' '{ $1=$1 ".fastq" }1' < metadata_temp.tsv > metadata2.tsv
			awk -v PC="$PC" -F "\t" -vOFS='\t' '$3~PC{print $2,$4,$5}' details.tsv > pc_metadata_temp.tsv
			awk -F "\t" -vOFS='\t' '{ $1=$1 ".fastq" }1' < pc_metadata_temp.tsv > pc_metadata2.tsv
			awk -v NC="$NC" -F "\t" -vOFS='\t' '$3~NC{print $2,$4,$5}' details.tsv > nc_metadata_temp.tsv
			awk -F "\t" -vOFS='\t' '{ $1=$1 ".fastq" }1' < nc_metadata_temp.tsv > nc_metadata2.tsv
			cat metadata_headers_only.tsv metadata2.tsv pc_metadata2.tsv nc_metadata2.tsv > metadata.tsv
			rm metadata2.tsv
			rm metadata_temp.tsv
			rm pc_metadata_temp.tsv
			rm nc_metadata_temp.tsv
			rm pc_metadata2.tsv
			rm nc_metadata2.tsv

			cd temp
			rm barcode-sample-16S.csv
			ls *fastq | while read i; do echo -e "$i\t$PWD/$i"; done > sample2.tsv
			mv sample2.tsv "$TMPDIR"/"$client"
			cd "$TMPDIR"/"$client"
			cat sample_headers_only.tsv sample2.tsv > sample.tsv
			rm sample2.tsv
			rm sample_headers_only.tsv
			rm metadata_headers_only.tsv

			## PB-16S workflow begins ###
<<comment
			#nextflow run /mnt/efs/fs1/pb-16S-nf/main3.nf --input sample.tsv --metadata metadata.tsv --dada2_cpu 37 --vsearch_cpu 37 -profile docker --outdir "$client"_Analysis -bucket-dir 's3://16s-pipeline/temp'

			### Create Analysis Directory, move files out to EFS & edit HTML ###

			cp -rL "$client"_Analysis/ "$EFS"/"$run_number"/"$client"/
			mv "$client"_Analysis/ Analysis/
			cd "$EFS"/"$run_number"/"$client"/Analysis/results
			cp "$EFS"/../../fs1/resources/project_info.txt .
			cp "$EFS"/../../fs1/resources/agrf_logo.txt .
			head -n 3394 visualize_biom.html > top.html
			sed -n '3395,3407p' visualize_biom.html > pre-info.html
			sed -n '3408,3596p' visualize_biom.html > post-info.html
			sed -i "s/ID: /ID: $client/g" project_info.txt
			sed -i "s/date: /date: $(date)/g" project_info.txt
			#sed -i "s/Client: /Client: $client/g" project_info.txt
			cat top.html agrf_logo.txt pre-info.html project_info.txt post-info.html > report.html
			rm pre-info* post-info* project_info* agrf_logo* top*
			touch "$EFS"/"$run_number"/"$client"/run_complete
comment
		else

			### Housekeeping just in case ###

			cd "$TMPDIR"/"$client"
			conda deactivate

			# Metadata and sample tsv creation

			awk -v client="$client" -F "\t" -vOFS='\t' '$3~client{print $2,$4,$5}' details.tsv > metadata_temp.tsv
			awk -F "\t" -vOFS='\t' '{ $1=$1 ".fastq" }1' < metadata_temp.tsv > metadata2.tsv
			awk -v PC="$PC" -F "\t" -vOFS='\t' '$3~PC{print $2,$4,$5}' details.tsv > pc_metadata_temp.tsv
			awk -F "\t" -vOFS='\t' '{ $1=$1 ".fastq" }1' < pc_metadata_temp.tsv > pc_metadata2.tsv
			awk -v NC="$NC" -F "\t" -vOFS='\t' '$3~NC{print $2,$4,$5}' details.tsv > nc_metadata_temp.tsv
			awk -F "\t" -vOFS='\t' '{ $1=$1 ".fastq" }1' < nc_metadata_temp.tsv > nc_metadata2.tsv
			cat metadata_headers_only.tsv metadata2.tsv pc_metadata2.tsv nc_metadata2.tsv > metadata.tsv
			rm metadata2.tsv
			rm metadata_temp.tsv
			rm pc_metadata_temp.tsv
			rm nc_metadata_temp.tsv
			rm pc_metadata2.tsv
			rm nc_metadata2.tsv

			mkdir temp
			cd temp
			cp "$EFS"/"$run_number"/"$client"/Demultiplexed/*.fastq .
			
			### Check and remove spaces in file names
			
			for file in *\ *; do
				new_file=${file// /}
				mv "$file" "$new_file"
			done
			
			ls *fastq | while read i; do echo -e "$i\t$PWD/$i"; done > sample2.tsv
			mv sample2.tsv $TMPDIR
			cd $TMPDIR
			cat sample_headers_only.tsv sample2.tsv > sample.tsv
			rm sample2.tsv


			### PB-16S workflow begins ###
<<comment
			#nextflow run /mnt/efs/fs1/pb-16S-nf/main3.nf --input sample.tsv --metadata metadata.tsv --dada2_cpu 37 --vsearch_cpu 37 -profile docker --outdir "$client"_Analysis -bucket-dir 's3://16s-pipeline/temp'

			### Create Analysis Directory, move files out to EFS & edit HTML ###

			cp -rL "$client"_Analysis/ "$EFS"/"$run_number"/"$client"/
			mv "$client"_Analysis/ Analysis/
			cd "$EFS"/"$run_number"/"$client"/Analysis/results
			cp "$EFS"/../../fs1/resources/project_info.txt .
			cp "$EFS"/../../fs1/resources/agrf_logo.txt .
			head -n 3394 visualize_biom.html > top.html
			sed -n '3395,3407p' visualize_biom.html > pre-info.html
			sed -n '3408,3596p' visualize_biom.html > post-info.html
			sed -i "s/ID: /ID: $client/g" project_info.txt
			sed -i "s/date: /date: $(date)/g" project_info.txt
			#sed -i "s/Client: /Client: $client/g" project_info.txt
			cat top.html agrf_logo.txt pre-info.html project_info.txt post-info.html > report.html
			rm pre-info* post-info* project_info* agrf_logo* top*
			touch "$EFS"/"$run_number"/"$client"/run_complete
comment
		fi
	echo ""$client" files are set-up."
	done < contracts.txt

script_end=`date`
script_runtime=$((script_end-script_start))

echo "Finished at "$script_end" minutes. Have a good day."
