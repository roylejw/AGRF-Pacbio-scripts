#!/bin/sh

sample=$1
hic1=$2
hic2=$3
fastq1=$4
fastq2=$5
instanceid=$6

if [ ! -e /home/ubuntu/"$hic1" ]; then
	echo "File "$hic1" not found. Check and restart"
	exit 1
fi

if [ ! -e /home/ubuntu/"$hic2" ]; then
	echo "File "$hic2" not found. Check and restart"
	exit 1
fi

if [ ! -e /home/ubuntu/"$fastq1" ]; then
	echo "File "$fastq1" not found. Check and restart"
	exit 1
fi

if [ ! -e /home/ubuntu/"$fastq2" ]; then
	echo "File "$fastq2" not found. Check and restart"
	exit 1
fi

mkdir /mnt/efs/fs2/output/hifiasm_"$sample"
cd /mnt/efs/fs2/output/hifiasm_"$sample"

if [ ! -e /home/ubuntu/combined.fastq ]; then
	cat /home/ubuntu/"$fastq1" /home/ubuntu/"$fastq2" > /home/ubuntu/combined.fastq
fi

/mnt/efs/fs1/hifiasm/hifiasm -o "$sample".hic.asm -t 48 --hg-size 3g --h1 /home/ubuntu/"$hic1" --h2 /home/ubuntu/"$hic2" /home/ubuntu/combined.fastq 2> "$sample".log

awk '/^S/{print ">"$2;print $3}' "$sample".hic.asm.hic.p_ctg.gfa > "$sample".primary.fasta
awk '/^S/{print ">"$2;print $3}' "$sample".hic.asm.hic.hap1.p_ctg.gfa > "$sample".hap1.fasta
awk '/^S/{print ">"$2;print $3}' "$sample".hic.asm.hic.hap2.p_ctg.gfa > "$sample".hap2.fasta

source ~/miniconda3/etc/profile.d/conda.sh

if [ ! -d ~/miniconda3/envs/quast ]; then
	cp /mnt/efs/fs1/resources/quast_share.yml .
	conda env create --file quast_share.yml
fi

conda activate quast

quast --large --no-snps --plots-format png -t 48 "$sample".primary.fasta "$sample".hap1.fasta "$sample".hap2.fasta

conda deactivate

if [ ! -d ~/miniconda3/envs/busco ]; then
	cp /mnt/efs/fs1/resources/busco_share.yml .
	conda env create --file busco_share.yml
fi

conda activate busco

busco -i "$sample".primary.fasta --auto-lineage-euk -o "$sample".primary_out -m genome -c 48
busco -i "$sample".hap1.fasta --auto-lineage-euk -o "$sample".hap1_out -m genome -c 48
busco -i "$sample".hap2.fasta --auto-lineage-euk -o "$sample".hap2_out -m genome -c 48

conda deactivate

if [ -e "$sample".hic.asm.hic.p_ctg.gfa ]; then
	aws ec2 stop-instances --instance-ids "$instanceid"
fi