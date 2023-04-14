#!/bin/sh

clear

echo "Script by Jack Royle, AGRF. Please email jack.royle@agrf.org.au if any issues."

echo "Remember, your answers are case-sensitive!!!"

echo "!!! Please make sure you run this in a screen! You will time-out your connection otherwise and lose your data!!!"
echo " !!! Do not include file prefixes in your filenames! Only the name!"
echo "What job are you wanting to complete? Select and type the number."
echo "1. Hifiasm assembly"
echo "2. Demultiplex data"
echo "3. Run stage 1 of the 16S pipeline (preparing data)"
echo "4. Run stage 2 of the 16S pipeline (Nextflow)"

read -r job_type

# Check to see if job selection is valid

MAX_TRIES=0
while [ "$job_type" -ge 5 ] || [ "$job_type" -le 0 ]; do
	if [ "$MAX_TRIES" == 3 ]; then 
		echo "Too many incorrect tries. Run me again and pick between 1 and 4!"
		exit 1
	fi
	echo "Selection "$job_type" invalid, please select between 1 to 4."
	MAX_TRIES=$((MAX_TRIES + 1))
	read -r job_type
done
MAX_TRIES=0


### HIFIASM ASSEMBLY ###


if [[ "$job_type" == 1 ]] ; then
	echo "You have selected "$job_type". Please rsync all files directly into the home directory (/home/ubuntu)"
	echo "What is the sample prefix you want to give to your assembly?"
	read -r sample
	
	# HiC data inclusion
	
	echo "Are you including HiC data? Yes or no."
	read -r hic_confirm
	
		if [ "$hic_confirm" == "yes" ]; then
			echo "What is the filename of the first file?"
			read -r hic1
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hic1".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hic1" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hic1
			fi
			echo "What is the filename of the second file?"
			read -r hic2
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hic2".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hic2" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hic2
			fi
		fi
	
	# Hifi cells 
	echo "How many cells of HiFi data are we assembling today?"
	read -r cells
	
	# 1 cell
	
		if [ "$cells" == 1 ]; then
			echo "What is the filename of cell 1?"
			read -r hifi1
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi1".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi1" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi1
			fi
		fi
		MAX_TRIES=0
	
	# 2 cells
	
		if [ "$cells" == 2 ]; then
			echo "What is the filename of cell 1?"
			read -r hifi1
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi1".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi1" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi1
			fi
			
			echo "What is the filename of cell 2?"
			read -r hifi2
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi2".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi2" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi2
			fi
		fi
	MAX_TRIES=0
	
	# 3 cells
	
		if [ "$cells" == 3 ]; then
			echo "What is the filename of cell 1?"
			read -r hifi1
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi1".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi1" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi1
			fi
			
			echo "What is the filename of cell 2?"
			read -r hifi2
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi2".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi2" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi2
			fi

			echo "What is the filename of cell 3?"
			read -r hifi3	
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi3".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi3" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi3
			fi			
		fi
	MAX_TRIES=0
	
	# 4 cells
	
		if [ "$cells" == 4 ]; then
			echo "What is the filename of cell 1?"
			read -r hifi1
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi1".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi1" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi1
			fi
			
			echo "What is the filename of cell 2?"
			read -r hifi2
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi2".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi2" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi2
			fi

			echo "What is the filename of cell 3?"
			read -r hifi3	
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi3".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi3" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi3
			fi			
			echo "What is the filename of cell 4?"
			read -r hifi4
			MAX_TRIES=0
			if [ ! -e /home/ubuntu/"$hifi4".* ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hifi4" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hifi4
			fi
		fi
	MAX_TRIES=0

	# Do we need to convert the files? Or unzip them?
	echo "Are you files bam, or fastq? Please note they all need to be the same!"
	read -r format
	
	# Option for Hifiasm assembly - affects some metrics.
	echo "What is your estimated genome size? Type a number + g for gigabase or m for megabase (ie 3g, 300m, etc)"
	read -r genome_size

	# Instance ID to turn off once finished
	echo "Tell me the AWS Instance ID - it should look like this: i-0834sdfa02384asd"
	read -r instanceid
	
	# Time to run the assembly
	echo "Time to run the job. Come back in ~14 hours or so. Please tell me you put me in a screen..."
	
	source ~/AGRF-Pacbio-scripts/scripts/assembly.sh	
fi

if [[ "$job_type" == 2 ]] ; then
	
	echo "You have selected "$job_type". Please rsync/filezilla all files directly into the home directory (/home/ubuntu)."
	echo "What is the filename of the sequencing file? Do not include its filetype."
	read -r filename
	echo "What is the format of the sequencing file? Options are bam or fastq.gz."
	read -r format	
	
	MAX_TRIES=0
	if [ ! -e /home/ubuntu/"$filename"."$format" ]; then
		if [ "$MAX_TRIES" == 3 ]; then 
			echo "Too many incorrect tries. Check your files and run me again!"
			exit 1
		fi
		echo "File "$filename"."$format" not found. Try again."
		MAX_TRIES=$((MAX_TRIES + 1))
		echo "What is the filename of the sequencing file? Do not include its filetype."
		read -r filename
		echo "What is the format of the sequencing file? Options are bam or fastq.gz."
		read -r format	
	fi
	
	echo  "What is the barcode set? Options: 16S, isoseq, M13, Universal. Type as seen (inc. capitals)"
	read -r barcode
	
	if [ "$barcode" != "isoseq" ]; then
		echo  "Are these symmetric or asymmetric?"
		read -r direction
	fi
	
	echo "What name would you like to give the output folder?"
	read -r outname
	
	echo "Running the demultiplex now."
	
	source ~/AGRF-Pacbio-scripts/scripts/demultiplex.sh
	echo "Demultiplex complete".
fi

if [[ "$job_type" == 3 ]] ; then
	echo "You have selected "$job_type". Please rsync/filezilla all files directly into the home directory (/home/ubuntu)."
	echo "Reminder - Pool party analysis requires two instances - one ubuntu & one AWS EC2. Make sure you git clone me into both!"
	echo "Please tell me the name of the batch folder you want the output to be called (ie. run_1, run_2, etc)."
	read -r run_number
	
	if [ ! -d /mnt/efs/fs2/pool_party/"$run_number" ]; then
		mkdir /mnt/efs/fs2/pool_party/"$run_number"
	fi
	
	echo "What is the filename of your HiFi data? Do not include the type (bam, fastq etc)!
	read -r filename
	
	echo "What is the format of your data? bam, or fastq.gz?
	read -r format
	
	MAX_TRIES=0
	if [ ! -e /home/ubuntu/"$filename"."$format" ]; then
		if [ "$MAX_TRIES" == 3 ]; then 
			echo "Too many incorrect tries. Check your files and run me again!"
			exit 1
		fi
		echo "File "$filename"."$format" not found. Try again."
		MAX_TRIES=$((MAX_TRIES + 1))
		echo "What is the filename of the sequencing file? Do not include its filetype."
		read -r filename
		echo "What is the format of the sequencing file? Options are bam or fastq.gz."
		read -r format	
	fi
	
	echo "Checking to see if you have synced in your details.tsv and contracts.txt..."
	sleep(1)
	echo "..."
	sleep(2)
	
	if [ -e /home/ubuntu/contracts.txt ]; then
		echo "List of contracts exists."
	elif [ ! -e /mnt/efs/fs2/pool_party/"$run_number"/contracts.txt ]; then
		echo "Error - contract list not present."
		echo "Verification failed."
		exit 1
	fi
	if [ -e /home/ubuntu/details.tsv ]; then
		echo "Details file exists."
	elif [ ! -e /home/ubuntu/details.tsv ]; then
		echo "Error - details tsv not present."
		echo "Verification failed."
		exit 1
	fi
	echo "Check complete, ready for blastoff."
	
	mv contracts.txt /mnt/efs/fs2/pool_party/"$run_number"/.
	mv details.tsv /mnt/efs/fs2/pool_party/"$run_number"/.
	mv "$filename"."$format" /mnt/efs/fs2/pool_party/"$run_number"/.
	source ~/AGRF-Pacbio-scripts/scripts/pool_party_step1.sh
fi

if [[ "$job_type" == 4 ]] ; then
	echo "You have selected "$job_type". Good news is I don't need much info from you."
	echo "Please tell me the name of the batch folder you gave in stage 1."
	read -r run_number
	
	if [ ! -d /mnt/efs/fs2/pool_party/"$run_number" ]; then
		MAX_TRIES=0
		if [ "$MAX_TRIES" == 3 ]; then 
			echo "Too many incorrect tries. Check your files and run me again!"
			exit 1
		fi
		echo "Batch folder not found. Try again."
		MAX_TRIES=$((MAX_TRIES + 1))
		echo "Please tell me the name of the batch folder you gave in stage 1."
		read -r run_number
	fi
	
	echo "Please tell me the AWS instance ID so I can turn the head node off when complete."
	read -r instance
	
	echo "Last question - is this batch complex enough to skip the NB classification? IE is it soil?
	read -r skipnb
	
	echo "Running stage two, please hold (for god knows how long).
	
	source ~/AGRF-Pacbio-scripts/scripts/pool_party_step2.sh
