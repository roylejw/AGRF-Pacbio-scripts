#!/bin/sh

cd ~

if [ "$format" == "bam" ]; then
	source ~/miniconda3/etc/profile.d/conda.sh
	if [ ! -d ~/miniconda3/envs/pbtk ]; then
		cp /mnt/efs/fs1/conda_envs/pbtk.yml .
		conda env create --file pbtk.yml
	fi
	
	conda activate pbtk

	if [ "$cells" == 1 ]; then
		echo "Indexing "$hifi1" bam file."
		pbindex "$hifi1"."$format"
		echo "Converting bam's to fastq's"
		bam2fastq -o "$sample" -u "$hifi1"."$format"
	fi
	
	if [ "$cells" == 2 ]; then
		echo "Indexing bam files."
		pbindex "$hifi1"."$format"
		pbindex "$hifi2"."$format"
		echo "Converting bam's to fastq's"
		bam2fastq -o "$sample"_1 -u "$hifi1"."$format"
		bam2fastq -o "$sample"_2 -u "$hifi2"."$format"
		cat "$sample"_1.fastq "$sample"_2.fastq > combined.fastq
	fi
	
	if [ "$cells" == 3 ]; then
		echo "Indexing bam files."
		pbindex "$hifi1"."$format"
		pbindex "$hifi2"."$format"
		pbindex "$hifi3"."$format"
		echo "Converting bam's to fastq's"
		bam2fastq -o "$sample"_1 -u "$hifi1"."$format"
		bam2fastq -o "$sample"_2 -u "$hifi2"."$format"
		bam2fastq -o "$sample"_3 -u "$hifi3"."$format"
		
		cat "$sample"_1.fastq "$sample"_2.fastq "$sample"_3.fastq > combined.fastq
	fi
	
	if [ "$cells" == 4 ]; then
		echo "Indexing "$hifi1""
		pbindex "$hifi1"."$format"
		echo "Indexing "$hifi2""
		pbindex "$hifi2"."$format"
		echo "Indexing "$hifi3""
		pbindex "$hifi3"."$format"
		echo "Indexing "$hifi4""
		pbindex "$hifi4"."$format"
		echo "Converting bam's to fastq's"
		bam2fastq -o "$sample"_1 -u "$hifi1"."$format"
		bam2fastq -o "$sample"_2 -u "$hifi2"."$format"
		bam2fastq -o "$sample"_3 -u "$hifi3"."$format"
		bam2fastq -o "$sample"_4 -u "$hifi4"."$format"
		
		cat "$sample"_1.fastq "$sample"_2.fastq "$sample"_3.fastq "$sample"_4.fastq > combined.fastq
	fi
	conda deactivate
fi

if [ "$format" == "fastq.gz" ]; then
	source ~/miniconda3/etc/profile.d/conda.sh

	if [ "$cells" == 1 ]; then
		gunzip "$hifi1"."$format"
		mv "$hifi1".fastq combined.fastq
	fi
	
	if [ "$cells" == 2 ]; then
		gunzip "$hifi1"."$format"
		gunzip "$hifi2"."$format"
		cat "$hifi1".fastq "$hifi2".fastq > combined.fastq
	fi
	
	if [ "$cells" == 3 ]; then
		gunzip "$hifi1"."$format"
		gunzip "$hifi2"."$format"
		gunzip "$hifi3"."$format"
		cat "$hifi1".fastq "$hifi2".fastq "$hifi3".fastq > combined.fastq
	fi
	
	if [ "$cells" == 4 ]; then
		gunzip "$hifi1"."$format"
		gunzip "$hifi2"."$format"
		gunzip "$hifi3"."$format"
		gunzip "$hifi4"."$format"
		cat "$hifi1".fastq "$hifi2".fastq "$hifi3".fastq "$hifi4".fastq> combined.fastq
	fi
fi

if [ "$format" == "fastq" ]; then
	source ~/miniconda3/etc/profile.d/conda.sh

	if [ "$cells" == 1 ]; then
		cp "$hifi1".fastq combined.fastq
	fi
	
	if [ "$cells" == 2 ]; then
		cat "$hifi1".fastq "$hifi2".fastq > combined.fastq
	fi
	
	if [ "$cells" == 3 ]; then
		cat "$hifi1".fastq "$hifi2".fastq "$hifi3".fastq > combined.fastq
	fi
	
	if [ "$cells" == 4 ]; then
		cat "$hifi1".fastq "$hifi2".fastq "$hifi3".fastq "$hifi4".fastq> combined.fastq
	fi
fi

if [ ! -e /home/ubuntu/combined.fastq ]; then
	echo "Something went wrong with preparing the fastq file"
	exit 1
fi

mkdir /mnt/efs/fs2/output/hifiasm_"$sample"
cd /mnt/efs/fs2/output/hifiasm_"$sample"

echo "Starting Hifiasm. Go get a coffee or 10."

if [ "$hic_confirm" == "yes" ]; then
	/mnt/efs/fs1/hifiasm/hifiasm -o "$sample".hic.asm -t 48 --hg-size "$genome_size" --h1 /home/ubuntu/"$hic1".fastq.gz --h2 /home/ubuntu/"$hic2".fastq.gz /home/ubuntu/combined.fastq 2> "$sample".log
	awk '/^S/{print ">"$2;print $3}' "$sample".hic.asm.hic.p_ctg.gfa > "$sample".primary.fasta
	awk '/^S/{print ">"$2;print $3}' "$sample".hic.asm.hic.hap1.p_ctg.gfa > "$sample".hap1.fasta
	awk '/^S/{print ">"$2;print $3}' "$sample".hic.asm.hic.hap2.p_ctg.gfa > "$sample".hap2.fasta

	source ~/miniconda3/etc/profile.d/conda.sh

	if [ ! -d ~/miniconda3/envs/quast ]; then
		cp /mnt/efs/fs1/resources/quast_share.yml .
		conda env create --file quast_share.yml
	fi

	conda activate quast
	echo "Starting QUAST."

	quast --large --no-snps --plots-format png -t 48 "$sample".primary.fasta "$sample".hap1.fasta "$sample".hap2.fasta

	echo "QUAST Finished."

	conda deactivate

	if [ ! -d ~/miniconda3/envs/busco ]; then
		cp /mnt/efs/fs1/resources/busco_share.yml .
		conda env create --file busco_share.yml
	fi

	conda activate busco

	echo "Starting BUSCO."

	busco -i "$sample".primary.fasta --auto-lineage-euk -o "$sample".primary_out -m genome -c 48
	busco -i "$sample".hap1.fasta --auto-lineage-euk -o "$sample".hap1_out -m genome -c 48
	busco -i "$sample".hap2.fasta --auto-lineage-euk -o "$sample".hap2_out -m genome -c 48

	echo "BUSCO Finished."

	conda deactivate

	if [ -e "$sample".hic.asm.hic.p_ctg.gfa ]; then
		aws ec2 stop-instances --instance-ids "$instanceid"
	fi
	
else

	/mnt/efs/fs1/hifiasm/hifiasm -o "$sample".asm -t 48 --hg-size "$genome_size" /home/ubuntu/combined.fastq 2> "$sample".log
	
	awk '/^S/{print ">"$2;print $3}' "$sample".asm.bp.p_ctg.gfa > "$sample".primary.fasta
	awk '/^S/{print ">"$2;print $3}' "$sample".asm.bp.hap1.p_ctg.gfa > "$sample".hap1.fasta
	awk '/^S/{print ">"$2;print $3}' "$sample".asm.bp.hap2.p_ctg.gfa > "$sample".hap2.fasta

	source ~/miniconda3/etc/profile.d/conda.sh

	if [ ! -d ~/miniconda3/envs/quast ]; then
		cp /mnt/efs/fs1/resources/quast_share.yml .
		conda env create --file quast_share.yml
	fi

	conda activate quast
	echo "Starting QUAST."

	quast --large --no-snps --plots-format png -t 48 "$sample".primary.fasta "$sample".hap1.fasta "$sample".hap2.fasta

	echo "QUAST Finished."

	conda deactivate

	if [ ! -d ~/miniconda3/envs/busco ]; then
		cp /mnt/efs/fs1/resources/busco_share.yml .
		conda env create --file busco_share.yml
	fi

	conda activate busco

	echo "Starting BUSCO."

	busco -i "$sample".primary.fasta --auto-lineage-euk -o "$sample".primary_out -m genome -c 48
	busco -i "$sample".hap1.fasta --auto-lineage-euk -o "$sample".hap1_out -m genome -c 48
	busco -i "$sample".hap2.fasta --auto-lineage-euk -o "$sample".hap2_out -m genome -c 48

	echo "BUSCO Finished."

	conda deactivate

	if [ -e "$sample".hic.asm.hic.p_ctg.gfa ]; then
		aws ec2 stop-instances --instance-ids "$instanceid"
	fi
fi
