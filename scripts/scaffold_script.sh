#!/bin/sh

### Scaffolding hifiasm assemblies with HiC data using AREMA recommended pipeline. Requires a fasta file & two HiC datasets (forward and reverse reads).

### This can be run on a fresh AWS instance, no pre-existing AMI required. Recommend an instance with 48 cores, and 192+ Gb of RAM. m5.12's do the job, or similar (testing spot instances still for savings - there's potential there).

sample=$1
hic_number=$2
threads=$3
instance=$4
hic_storage=/mnt/efs/fs2/input/pangenome/hic
assembly=/mnt/efs/fs2/output/hifiasm_"$sample"/"$sample".primary.fasta
home="$home"

export sample
export hic_number
export threads
export instance
export hic_storage
export assembly
export home

sudo yum install -y amazon-efs-utils
aws configure

## List of HiC reads for reference

#A3_1=Maddie-HiC-A3_S3_L001_R1_001.fastq.gz
#A3_2=Maddie-HiC-A3_S3_L001_R2_001.fastq.gz
#A7_1=Maddie-HiC-A7_S4_L001_R1_001.fastq.gz
#A7_2=Maddie-HiC-A7_S4_L001_R2_001.fastq.gz
#D4_1=Maddie-HiC-D4_S6_L001_R1_001.fastq.gz
#D4_2=Maddie-HiC-D4_S6_L001_R2_001.fastq.gz
#H5_1=Maddie-HiC-H5_S5_L001_R1_001.fastq.gz
#H5_2=Maddie-HiC-H5_S5_L001_R2_001.fastq.gz
#T1=Maddie-HiC-T1_S2_L001_R1_001.fastq.gz
#T1=Maddie-HiC-T1_S2_L001_R2_001.fastq.gz
#W2_1=Maddie-HiC-W2_S1_L001_R1_001.fastq.gz
#W2_2=Maddie-HiC-W2_S1_L001_R2_001.fastq.gz
#H1_1=Maddie-HiC-NS_S2_L001_R1_001.fastq.gz
#H1_2=Maddie-HiC-NS_S2_L001_R2_001.fastq.gz

<< COMMENT
# If instance is has SSD attached (m5ad spots), use this to attach them. Check the nvme names (can change between instance types), and change home variable to /data1 or /data2

sudo mkfs -t xfs /dev/nvme1n1
sudo mkfs -t xfs /dev/nvme2n1

sudo mkdir /data1
sudo mkdir /data2

sudo mount /dev/nvme1n1 /data1 && sudo chmod 777 /data1
sudo mount /dev/nvme2n1 /data2 && sudo chmod 777 /data2
COMMENT

# Mount existing AGRF EFS storage to instance

sudo mkdir /mnt/efs
if [ ! -d /mnt/efs/fs2/ ]; then
	sudo mkdir /mnt/efs/fs2
fi
sudo mount -t efs -o tls fs-018fdbc24abe8afd5:/ /mnt/efs/fs2

if [ ! -d /mnt/efs/fs1/ ]; then
	sudo mkdir /mnt/efs/fs1
fi
sudo mount -t efs -o tls fs-0d05585280ab96dd4:/ /mnt/efs/fs1

# Setup instance installs

sudo yum install -y make git libxml2 libxml2-devel libxslt libxslt-devel glibc-devel gcc patch gcc-c++ perl git

if [ ! -d "$home"/mambaforge ]; then
	wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
	bash Mambaforge-Linux-x86_64.sh -b
fi

source "$home"/mambaforge/bin/activate
eval "$(conda shell.bash hook)"
source "$home"/mambaforge/etc/profile.d/mamba.sh

##Installing bwa-mem2 

cd "$home"

if [ ! -d "$home"/bwa-mem2 ]; then
	git clone --recursive https://github.com/bwa-mem2/bwa-mem2
	cd bwa-mem2
	make
fi

##Install samtools

if [ ! -d "$home"/mambaforge/envs/samtools ]; then
	mamba create -n samtools
	conda activate samtools
	mamba install -c bioconda samtools -y
	conda deactivate
fi

## Installing Picard tools

 if [ ! -d "$home"/mambaforge/envs/picard ]; then
	mamba create -n picard
	conda activate picard
	mamba install -c bioconda picard -y
	conda deactivate
fi 

# Mapping HiC to contig assemblies

cd "$home"
mkdir "$sample"
cd "$sample"

conda activate samtools

samtools --version

../bwa-mem2/bwa-mem2 index -p "$sample" "$assembly"

../bwa-mem2/bwa-mem2 mem -SP5M -t "$threads" "$sample" "$hic_storage"/Maddie-HiC-"$hic_number"_L001_R1_001.fastq.gz  "$hic_storage"/Maddie-HiC-"$hic_number"_L001_R2_001.fastq.gz | samtools view -bhS > "$sample"_aligned.bam

cd ..
cp -rp "$sample" /mnt/efs/fs2/input/pangenome/out_bwa/.
cd "$sample"

samtools sort -@ "$threads" -O bam "$sample"_aligned.bam > "$sample"_aligned_sorted.bam

cd ..
cp -rp "$sample" /mnt/efs/fs2/input/pangenome/out_bwa/.



## Picard ReadGroup editing & duplicate removal
conda deactivate
conda activate picard

cd "$home"/"$sample"

java -Xmx30G -jar "$home"/mambaforge/envs/picard/share/picard-3.1.0-0/picard.jar AddOrReplaceReadGroups I="$sample"_aligned_sorted.bam O="$sample"_aligned.readgroup.bam ID="$sample" LB="$sample" SM="$sample" PL=ILLUMINA PU=none

java -Xmx90G -XX:-UseGCOverheadLimit -jar "$home"/mambaforge/envs/picard/share/picard-3.1.0-0/picard.jar MarkDuplicates I="$sample"_aligned.readgroup.bam O="$sample"_markdup.bam M=metrics.txt ASSUME_SORTED=TRUE VALIDATION_STRINGENCY=LENIENT REMOVE_DUPLICATES=TRUE 

cp -rp "$sample"_markdup.bam /mnt/efs/fs2/input/pangenome/out_bwa/"$sample"/.



### YAHS Scaffolding

cd "$home"/"$sample"
conda activate samtools
samtools faidx "$assembly"
cd ..
git clone https://github.com/c-zhou/yahs.git
cd yahs
make
cd ../"$sample"
../yahs/yahs -o "$sample" "$assembly" "$sample"_markdup.bam 
mkdir /mnt/efs/fs2/output/"$sample"_scaffolds
cp -rp "$sample"_scaffolds_final.* /mnt/efs/fs2/output/"$sample"_scaffolds/.

### QUAST report

mamba install -c bioconda -y quast
cd /mnt/efs/fs2/output/"$sample"_scaffolds
quast --large --no-snps --plots-format png -t 48 "$sample"_scaffolds_final.fa
 

###

 


