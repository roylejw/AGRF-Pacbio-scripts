#!/bin/sh

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
			if [ ! -e /home/ubuntu/"$hic1" ]; then
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
			if [ ! -e /home/ubuntu/"$hic2" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi1" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi1" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi2" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi1" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi2" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi3" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi1" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi2" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi3" ]; then
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
			if [ ! -e /home/ubuntu/"$hifi4" ]; then
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

