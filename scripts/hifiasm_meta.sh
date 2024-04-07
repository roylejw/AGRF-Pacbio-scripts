#!/bin/sh

cd ~

source ~/miniconda3/etc/profile.d/conda.sh

cp /mnt/efs/fs1/conda_envs/pbtk.yml .
conda env create --file pbtk.yml

conda activate pbtk

format=bam

for file in *."$format"; do
    if [ -f "$file" ]; then
        echo "Indexing $file"
        pbindex "$file"
        echo "Converting bam's to fastq's"
        sample2=$(basename "$file" ".$format")
        bam2fastq -o "${sample2}" "$file"
    fi
done

cat *.fastq > combined.fastq


AWS_ACCESS_KEY_ID=$(grep 'AWS_ACCESS_KEY_ID' /mnt/efs/fs1/resources/aws_credentials.txt | cut -d '=' -f2)
AWS_SECRET_ACCESS_KEY=$(grep 'AWS_SECRET_ACCESS_KEY' /mnt/efs/fs1/resources/aws_credentials.txt | cut -d '=' -f2)

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"

mkdir hifiasm_"$sample"
cd hifiasm_"$sample"

/mnt/efs/fs1/hifiasm-meta/hifiasm_meta -t "$threads" -o asm combined.fastq.gz 2>asm.log


awk '/^S/{print ">"$2;print $3}' *.p_ctg*.gfa > "$sample".primary.fasta

mkdir -p "$client"/"$sample"/Assembly

cp "$sample".primary.fasta "$client"/"$sample"/Assembly/.

aws s3 cp --recursive /home/"$instance_build"/hifiasm_"$sample"/"$client"/ s3://hifiasm-out/"$client"/

filesize=$(stat -c "%s" "$sample".primary.fasta)
one_megabyte=$((1024 * 1024))

if [ "$filesize" -gt "$one_megabyte" ]; then
	aws ec2 stop-instances --instance-ids "$instanceid"
else
	echo "Something is weird, check the outputs and logs to see what went wrong."
	touch something_wrong.txt
fi
