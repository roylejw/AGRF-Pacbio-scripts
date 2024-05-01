#!/bin/sh
echo "Script by Jack Royle, AGRF. Please email jack.royle@agrf.org.au if any issues."
source ~/miniconda3/etc/profile.d/conda.sh
sudo yum install -y zip dos2unix

if [ ! -d ~/miniconda3/envs/pbtk ]; then
	cp /mnt/efs/fs1/conda_envs/pbtk.yml .
	conda env create --file pbtk.yml
fi
  
script_start=`date +%M`

if [ -d /mnt/efs/fs2/pool_party_ITS/"$run_number" ]; then
	echo "Run folder exists."
elif [ ! -d /mnt/efs/fs2/pool_party_ITS/"$run_number" ]; then
	echo "Error - run folder not present."
	echo "Verification failed."
exit 1
fi

if [ -e /mnt/efs/fs2/pool_party_ITS/"$run_number"/"$filename"."$format" ]; then
	echo "CCS file exists."
elif [ ! -e /mnt/efs/fs2/pool_party_ITS/"$run_number"/"$filename"."$format" ]; then
	echo "Error - CCS file not present."
	echo "Verification failed."
	exit 1
fi

if [ -e /mnt/efs/fs2/pool_party_ITS/"$run_number"/contracts.txt ]; then
	echo "List of contracts exists."
elif [ ! -e /mnt/efs/fs2/pool_party_ITS/"$run_number"/contracts.txt ]; then
	echo "Error - contract list not present."
	echo "Verification failed."
	exit 1
fi

if [ -e /mnt/efs/fs2/pool_party_ITS/"$run_number"/details.tsv ]; then
	echo "Details file exists."
elif [ ! -e /mnt/efs/fs2/pool_party_ITS/"$run_number"/details.tsv ]; then
	echo "Error - details tsv not present."
	echo "Verification failed."
	exit 1
fi

if [[ "$kinnex" == "yes" ]] ; then
	if [ ! -f "/mnt/efs/fs2/pool_party_ITS/$run_number/skera-complete" ]; then
        conda activate pbtk
        conda install -y -c bioconda pbskera
        cp /mnt/efs/fs1/resources/mas12_primers.fasta .
       	rm /mnt/efs/fs2/pool_party_ITS/"$run_number"/"$filename"."$format"
        mv "$filename"."$format" skera.bam
        skera split skera.bam mas12_primers.fasta "$filename"."$format"
		touch /mnt/efs/fs2/pool_party_ITS/"$run_number"/skera-complete
        cp "$filename"."$format" /mnt/efs/fs2/pool_party_ITS/"$run_number"/"$filename"."$format"
	else
       	echo "Deconcatination already executed. Skipping."
	fi
fi

cd /mnt/efs/fs2/pool_party_ITS/"$run_number"
echo "Dos2Unix'ing the input files."
dos2unix contracts.txt
dos2unix details.tsv

	while read client || [[ $client ]]; do
		echo "Setting up "$client". Time started is" && date
		

		### Housekeeping - no need to change ###
		EFS="/mnt/efs/fs2/pool_party_ITS"
		PC=PC
		NC=NC
		TMPDIR="/mnt/efs/fs1/temp_ITS"

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
		if [[ "$kinnex" == "yes" ]] ; then
    			cp "$EFS"/../../fs1/resources/kinnex16S.fasta .
       			mv kinnex16S.fasta 16S.fasta
	  	else
    			cp "$EFS"/../../fs1/resources/16S.fasta .
       		fi
		cp "$EFS"/../../fs1/resources/lima_headers_only.csv .
		cp "$EFS"/../../fs1/resources/sample_headers_only.tsv .
		cp "$EFS"/../../fs1/resources/metadata_headers_only_ITS.tsv .

		# Check and remove spaces from client submitted sample names and all other columns - probably super inefficient but IDC
  
	awk -F "\t" '{
		gsub(/ /,"",$1);
		gsub(/ /,"",$2);
		gsub(/ /,"",$3);
		gsub(/ /,"",$4);
		gsub(/ /,"",$5);
		print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5
	}' details.tsv > details2.tsv && mv details2.tsv details.tsv

		# Make client project directory in EFS

		if [ ! -f "$EFS"/"$run_number"/"$client"/demux_complete ]; then
			mkdir "$EFS"/"$run_number"/"$client"
		fi

		# Create Lima 16S barcoding csv

		awk -v client="$client" -F "\t" -vOFS="," '$3~client{print $1,$2}' details.tsv > barcode-sample.csv
		awk -v PC="$PC" -F "\t" -vOFS="," '$3==PC{print $1,$2}' details.tsv > barcode-sample-pc.csv
		awk -v NC="$NC" -F "\t" -vOFS="," '$3==NC{print $1,$2}' details.tsv > barcode-sample-nc.csv
		cat lima_headers_only.csv barcode-sample.csv barcode-sample-pc.csv barcode-sample-nc.csv > barcode-sample-ITS.csv
		#cat lima_headers_only.csv barcode-sample.csv > barcode-sample-ITS.csv
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
					conda activate pbtk
					pbindex "$filename"."$format"
					cd "$TMPDIR"/"$client"
					conda deactivate
				fi
				if [ ! -f "$EFS"/"$run_number"/"$filename".fastq ]; then
					echo "Converting Bam to Fastq."
					cd "$EFS"/"$run_number"
					conda activate pbtk
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
			
			conda activate pbtk
			format=fastq
			echo "Running Lima - started at" && date
   			num_cpus=$(nproc)
			lima -j "$num_cpus" --hifi-preset ASYMMETRIC --biosample-csv barcode-sample-ITS.csv --split-named --output-missing-pairs "$EFS"/"$run_number"/"$filename"."$format" 16S.fasta demux."$format" 
   			conda deactivate
			echo "Finished Lima at" && date
			
			### Create directory, format and rename demultiplexed samples ###
			echo "Reformatting demultiplexed samples and creating metadata files."
			
			if [ ! -d "$EFS"/"$run_number"/"$client"/Demultiplexed ]; then
				mkdir "$EFS"/"$run_number"/"$client"/Demultiplexed
			fi

			mkdir temp
			mv demux.bc* temp/.
			cd temp
			cp ../barcode-sample-ITS.csv .
			rename demux.bc bc *

			sed 's/"//g' barcode-sample-ITS.csv | while IFS=, read orig new; do mv "$orig"."$format" "$new"."$format"; done
			
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

			### New samples sheet creation - filters samples below n reads (currently 1000)

			cd temp
			rm barcode-sample-ITS.csv
   			ls *fastq | while read i; do count=$(grep -o 'ccs' "$i" | wc -l); if [ "$count" -gt 1000 ]; then echo -e "$i\t$PWD/$i"; fi; done > sample2.tsv
      			ls *fastq | while read i; do count=$(grep -o 'ccs' "$i" | wc -l); if [ "$count" -le 8000 ]; then echo $i; fi; done > samples_below_threshold.tsv
			mv sample2.tsv "$TMPDIR"/"$client"
   			mv samples_below_threshold.tsv "$TMPDIR"/"$client"
			cd "$TMPDIR"/"$client"
			cat sample_headers_only.tsv sample2.tsv > sample.tsv
			rm sample_headers_only.tsv

			### New metadata sheet creator - uses the sample2.tsv created above to filter the details.tsv and create a metadata file for the run with only passing samples
   
   			filtered_files=$(awk '{print $1}' sample2.tsv)
			awk -vOFS='\t' -v filtered_files="$filtered_files" 'BEGIN { split(filtered_files, arr, " "); for (i in arr) filtered[arr[i]] } $2 ".fastq" in filtered { print $2 ".fastq", $4 }' details.tsv > metadata2.tsv
   			cat metadata_headers_only_ITS.tsv metadata2.tsv > metadata.tsv
      			rm sample2.tsv
			rm metadata2.tsv
			rm metadata_headers_only_ITS.tsv

		else

			### Housekeeping just in case ###

			cd "$TMPDIR"/"$client"
			conda deactivate

			### Copies previously demuxed fastq's in to temp folder

   			mkdir temp
			cd temp
			cp "$EFS"/"$run_number"/"$client"/Demultiplexed/*.fastq .

			### Check and remove spaces in file names
			
			for file in *\ *; do
				new_file=${file// /}
				mv "$file" "$new_file"
			done

   			### New samples sheet creation - filters samples below n reads (currently 1000)
			cd temp
			rm barcode-sample-ITS.csv
   			ls *fastq | while read i; do count=$(grep -o 'ccs' "$i" | wc -l); if [ "$count" -gt 1000 ]; then echo -e "$i\t$PWD/$i"; fi; done > sample2.tsv
      			ls *fastq | while read i; do count=$(grep -o 'ccs' "$i" | wc -l); if [ "$count" -le 8000 ]; then echo $i; fi; done > samples_below_threshold.tsv
			mv sample2.tsv "$TMPDIR"/"$client"
   			mv samples_below_threshold.tsv "$TMPDIR"/"$client"
			cd "$TMPDIR"/"$client"
			cat sample_headers_only.tsv sample2.tsv > sample.tsv
			rm sample_headers_only.tsv

			### New metadata sheet creator - uses the sample2.tsv created above to filter the details.tsv and create a metadata file for the run with only passing samples
   
   			filtered_files=$(awk '{print $1}' sample2.tsv)
			awk -vOFS='\t' -v filtered_files="$filtered_files" 'BEGIN { split(filtered_files, arr, " "); for (i in arr) filtered[arr[i]] } $2 ".fastq" in filtered { print $2 ".fastq", $4 }' details.tsv > metadata2.tsv
   			cat metadata_headers_only_ITS.tsv metadata2.tsv > metadata.tsv
      			rm sample2.tsv
			rm metadata2.tsv
			rm metadata_headers_only_ITS.tsv
		fi
		
	echo ""$client" files are set-up."
	done < contracts.txt
echo "Finished demultiplexing!"

### STEP 2 ###

### Housekeeping - no need to change ###
EFS="/mnt/efs/fs2/pool_party_ITS"
TMPDIR="/mnt/efs/fs1/temp_ITS"
contracts=""$EFS"/"$run_number"/"contracts.txt""
client=""
conda activate base

# Read AWS credentials from file
AWS_ACCESS_KEY_ID=$(grep 'AWS_ACCESS_KEY_ID' /mnt/efs/fs1/resources/aws_credentials.txt | cut -d '=' -f2)
AWS_SECRET_ACCESS_KEY=$(grep 'AWS_SECRET_ACCESS_KEY' /mnt/efs/fs1/resources/aws_credentials.txt | cut -d '=' -f2)

# Configure AWS CLI with credentials
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"

cd "$TMPDIR"

while read client || [[ $client ]]; do
 	dos2unix metadata.tsv
  	dos2unix sample.tsv
	cd "$client"
	rm report_"$client"_Analysis/*
	nextflow run /mnt/efs/fs1/pb-ITS-nf/main.nf --input sample.tsv --metadata metadata.tsv --dada2_cpu 94 --vsearch_cpu 94 --skip_nb true -profile docker --outdir "$client"_Analysis -bucket-dir 's3://its-pipeline-lgr/temp' --downsample "$downsample" -resume
	
	### Create Analysis Directory, move files out to EFS & edit HTML ###
	
	mkdir "$EFS"/"$run_number"/"$client"
	cp -rL "$client"_Analysis/ "$EFS"/"$run_number"/"$client"/
	cd "$EFS"/"$run_number"/"$client"/
	mv "$client"_Analysis/ Analysis/
	cd Analysis/results	
	
# THIS NEEDS TO BE TESTED AND MODIFIED WHEN RUN FIRST TIME
	
	#cp /mnt/efs/fs1/resources/project_info.txt .
	#cp /mnt/efs/fs1/resources/agrf_logo.txt .
	#head -n 3394 visualize_biom.html > top.html
	#sed -n '3395,3407p' visualize_biom.html > pre-info.html
	#sed -n '3408,3596p' visualize_biom.html > post-info.html
	#sed -i "s/ID: /ID: $client/g" project_info.txt
	#sed -i "s/date: /date: $(date)/g" project_info.txt
	#sed -i "s/Client: /Client: $client/g" project_info.txt
	#cat top.html agrf_logo.txt pre-info.html project_info.txt post-info.html > report.html
	#mv report.html "$EFS"/"$run_number"/"$client"/ITS_analysis_report.html
	
## CARRY ON HERE
	mv visualize_biom.html "$EFS"/"$run_number"/"$client"/ITS_analysis_report.html
	#rm pre-info* post-info* project_info* agrf_logo* top*
	cd "$EFS"/"$run_number"/"$client"/
	touch "$EFS"/"$run_number"/"$client"/run_complete
	cd "$EFS"/"$run_number"/"$client"/
 	zip -r ITS_Analysis.zip Analysis/
  	zip -r Demultiplexed.zip Demultiplexed/
  	rm -rf Analysis
   	rm -rf Demultiplexed
 	cd "$TMPDIR"
  done < "$contracts"

aws s3 cp --recursive "$EFS"/"$run_number"/ s3://its-out/"$run_number"/

aws ec2 stop-instances --instance-ids "$instance"
