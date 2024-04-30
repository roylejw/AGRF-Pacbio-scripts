#!/bin/sh

clear

echo "Script by Jack Royle, AGRF. Please email jack.royle@agrf.org.au if any issues."

echo "Remember, your answers are case-sensitive!!!"

echo "!!! Please make sure you run this in a screen! You will time-out your connection otherwise and lose your data!!!"
echo "What job are you wanting to complete? Select and type the number."
echo "1. Hifiasm assembly"
echo "2. Run the 16S pipeline"
echo "3. Run the ITS pipeline"
echo "4. Run hifiasm_meta - metagenome assembly"

instance_build=$(whoami)

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
	echo "You have selected "$job_type". Please rsync all files directly into the home directory"
	echo "Please ensure you only have one sample's data files in this folder! Start another instance, or delete the input files after running before starting a different sample."
	echo "Here are your files currently in the home directory"
	ls -l
	echo ""

 	echo "What is the client code for this project?"
  	read -r client
   
	echo "What is the sample prefix you want to give to your assembly? Please ensure this is unique for the project code you gave above."
 	echo "If the sample name is not unique, you will overwrite other samples within the client code you've given."
	read -r sample
	
	# HiC data inclusion
	
	echo "Are you including HiC data? yes or no."
	read -r hic_confirm
	
		if [ "$hic_confirm" == "yes" ]; then
			echo "What is the filename of the first file?"
			read -r hic1
			MAX_TRIES=0
			if [ ! -e /home/"$instance_build"/"$hic1".fastq.gz ]; then
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
			if [ ! -e /home/"$instance_build"/"$hic2".fastq.gz ]; then
				if [ "$MAX_TRIES" == 3 ]; then 
					echo "Too many incorrect tries. Check your files and run me again!"
					exit 1
				fi
				echo "File "$hic2" not found. Try again."
				MAX_TRIES=$((MAX_TRIES + 1))
				read -r hic2
			fi
		fi
	
	# Do we need to convert the files? Or unzip them?
	echo "Are you files bam, fastq.gz, or fastq? Please note they all need to be the same!"
	read -r format
	
	# Option for Hifiasm assembly - affects some metrics.
	echo "What is your estimated genome size? Type a number + g for gigabase or m for megabase (ie 3g, 300m, etc)"
	read -r genome_size

 	echo "How many CPUs is your instance running?"
  	read -r cpu_choice

	# Instance ID to turn off once finished
	echo "Tell me the AWS Instance ID - it should look like this: i-0834sdfa02384asd"
	read -r instanceid
	
	# Time to run the assembly
	echo "Time to run the job. Come back in ~14 hours or so. Please tell me you put me in a screen..."
	
	source ~/PacBio-related-scripts/scripts/assembly.sh	
fi

if [[ "$job_type" == 2 ]] ; then
	echo "You have selected "$job_type". Please rsync/filezilla all files directly into the home directory (/home/ec2-user)."
	echo "Make sure you have used 'screen' before running me. If not, press CTRL + C, and type screen. Then re-run me."
	sleep 1
	echo "Please tell me the name of the batch folder you want the output to be called (ie. run_1, run_2, etc)."
	ls -la /mnt/efs/fs2/pool_party
 	read -r run_number
	
	if [ ! -d /mnt/efs/fs2/pool_party/"$run_number" ]; then
		mkdir /mnt/efs/fs2/pool_party/"$run_number"
	fi
	
	echo "What is the filename of your HiFi data? Copy-paste the full name from the list below (THIS NOW INCLUDES THE FILE EXTENSION)!"
	ls -la
 	read -r full_filename
	
	filename="${full_filename%.*}"  # removes extension
	format="${full_filename##*.}"  # extracts extension
	
	echo "Filename: $filename"
	echo "Filetype: $format"

	MAX_TRIES=0
	if [ ! -e ~/"$filename"."$format" ]; then
		if [ "$MAX_TRIES" == 3 ]; then 
			echo "Too many incorrect tries. Check your files and run me again!"
			exit 1
		fi
		echo "File "$filename"."$format" not found. Try again."
		MAX_TRIES=$((MAX_TRIES + 1))
		echo "What is the filename of your HiFi data? Copy-paste the full name from the list below (THIS NOW INCLUDES THE FILE EXTENSION)!"
		ls -la
		read -r full_filename
		filename="${full_filename%.*}"  # removes extension
		format="${full_filename##*.}"  # extracts extension
	fi

        echo "Is this a Kinnex 16S/ITS dataset? Does it need to segment the reads first? Answer 'yes' or 'no'."
        read -r kinnex

	echo "What would you like to downsample to (default is 100000 per sample - press enter if you're happy with that value)"
	read -r downsample
	if [ -z "$downsample" ]; then
		downsample=100000
	fi
	
	echo "Please tell me the AWS instance ID so I can turn the head node off when complete."
	read -r instance
	
	echo "Checking to see if you have synced in your details.tsv and contracts.txt..."
	sleep 1
	echo "..."
	sleep 2
	
	if [ -e ~/contracts.txt ]; then
		echo "List of contracts exists."
	elif [ ! -e /mnt/efs/fs2/pool_party/"$run_number"/contracts.txt ]; then
		echo "Error - contract list not present."
		echo "Verification failed."
		exit 1
	fi
	if [ -e ~/details.tsv ]; then
		echo "Details file exists."
	elif [ ! -e ~/details.tsv ]; then
		echo "Error - details tsv not present."
		echo "Verification failed."
		exit 1
	fi
	echo "Check complete, ready for blastoff."
	
	cp contracts.txt /mnt/efs/fs2/pool_party/"$run_number"/.
	cp details.tsv /mnt/efs/fs2/pool_party/"$run_number"/.
 	if [ ! -f /mnt/efs/fs2/pool_party/"$run_number"/"$filename"."$format" ]; then
  		cp "$filename"."$format" /mnt/efs/fs2/pool_party/"$run_number"/.
    	fi
	source ~/PacBio-related-scripts/scripts/combined_16S_analysis.sh
fi

if [[ "$job_type" == 3 ]] ; then
	echo "You have selected "$job_type". Please rsync/filezilla all files directly into the home directory (/home/ec2-user)."
	echo "Make sure you have used 'screen' before running me. If not, press CTRL + C, and type screen. Then re-run me."
	sleep 1
	echo "Please tell me the name of the batch folder you want the output to be called (ie. run_1, run_2, etc)."
	ls -la /mnt/efs/fs2/pool_party_ITS
 	read -r run_number
	
	if [ ! -d /mnt/efs/fs2/pool_party_ITS/"$run_number" ]; then
		mkdir /mnt/efs/fs2/pool_party_ITS/"$run_number"
	fi
	
	echo "What is the filename of your HiFi data? Copy-paste the full name from the list below (THIS NOW INCLUDES THE FILE EXTENSION)!"
	ls -la
 	read -r full_filename
	
	filename="${full_filename%.*}"  # removes extension
	format="${full_filename##*.}"  # extracts extension
	
	echo "Filename: $filename"
	echo "Filetype: $format"

	MAX_TRIES=0
	if [ ! -e ~/"$filename"."$format" ]; then
		if [ "$MAX_TRIES" == 3 ]; then 
			echo "Too many incorrect tries. Check your files and run me again!"
			exit 1
		fi
		echo "File "$filename"."$format" not found. Try again."
		MAX_TRIES=$((MAX_TRIES + 1))
		echo "What is the filename of your HiFi data? Copy-paste the full name from the list below (THIS NOW INCLUDES THE FILE EXTENSION)!"
		ls -la
		read -r full_filename
		filename="${full_filename%.*}"  # removes extension
		format="${full_filename##*.}"  # extracts extension
	fi
	
        echo "Is this a Kinnex 16S/ITS dataset? Does it need to segment the reads first? Answer 'yes' or 'no'."
        read -r kinnex

	echo "What would you like to downsample to (default is 100000 per sample - press enter if you're happy with that value)"
	read -r downsample
	if [ -z "$downsample" ]; then
		downsample=100000
	fi
	
	echo "Please tell me the AWS instance ID so I can turn the head node off when complete."
	read -r instance
	
	echo "Checking to see if you have synced in your details.tsv and contracts.txt..."
	sleep 1
	echo "..."
	sleep 2
	
	if [ -e ~/contracts.txt ]; then
		echo "List of contracts exists."
	elif [ ! -e /mnt/efs/fs2/pool_party_ITS/"$run_number"/contracts.txt ]; then
		echo "Error - contract list not present."
		echo "Verification failed."
		exit 1
	fi
	if [ -e ~/details.tsv ]; then
		echo "Details file exists."
	elif [ ! -e ~/details.tsv ]; then
		echo "Error - details tsv not present."
		echo "Verification failed."
		exit 1
	fi
	echo "Check complete, ready for blastoff."
	
	cp contracts.txt /mnt/efs/fs2/pool_party_ITS/"$run_number"/.
	cp details.tsv /mnt/efs/fs2/pool_party_ITS/"$run_number"/.
 	if [ ! -f /mnt/efs/fs2/pool_party_ITS/"$run_number"/"$filename"."$format" ]; then
  		cp "$filename"."$format" /mnt/efs/fs2/pool_party_ITS/"$run_number"/.
    	fi
	source ~/PacBio-related-scripts/scripts/combined_ITS_analysis.sh
fi

if [[ "$job_type" == 4 ]] ; then

	echo "What is the client code for this project?"
	read -r client

	echo "What is the sample prefix you want to give to your assembly? Please ensure this is unique for the project code you gave above."
	echo "If the sample name is not unique, you will overwrite other samples within the client code you've given."
	read -r sample

	echo "How many CPUs is your instance running?"
	read -r threads

	echo "Tell me the AWS Instance ID - it should look like this: i-0834sdfa02384asd"
	read -r instanceid

	source ~/PacBio-related-scripts/scripts/hifiasm_meta.sh	
fi
