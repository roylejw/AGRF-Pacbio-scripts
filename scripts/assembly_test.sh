#!/bin/sh

instance_build=$(whoami)

cd ~

source ~/miniconda3/etc/profile.d/conda.sh

if [ "$format" == "bam" ]; then
    if [ ! -d ~/miniconda3/envs/pbtk ]; then
        cp /mnt/efs/fs1/conda_envs/pbtk.yml .
        conda env create --file pbtk.yml
    fi

    conda activate pbtk

    for file in *."$format"; do
        if [ -f "$file" ]; then
            echo "Indexing $file"
            pbindex "$file"
            echo "Converting bam's to fastq's"
            sample=$(basename "$file" ".$format")
            bam2fastq -o "${sample}" -u "$file"
        fi
    done

    # Combine all generated fastq files
    cat *.fastq > combined.fastq

    conda deactivate
fi

if [ "$format" == "fastq.gz" ] || [ "$format" == "fastq" ]; then
    for file in *."$format"; do
        if [ -f "$file" ]; then
            if [ "$format" == "fastq.gz" ]; then
                gunzip "$file"
                mv "${file%.gz}" "${sample}_${i}.fastq"
            else
                mv "$file" "${sample}_${i}.fastq"
            fi
        fi
    done

    # Combine all generated fastq files
    cat "${sample}"_*.fastq > combined.fastq
fi

# Read AWS credentials

AWS_ACCESS_KEY_ID=$(grep 'AWS_ACCESS_KEY_ID' /mnt/efs/fs1/resources/aws_credentials.txt | cut -d '=' -f2)
AWS_SECRET_ACCESS_KEY=$(grep 'AWS_SECRET_ACCESS_KEY' /mnt/efs/fs1/resources/aws_credentials.txt | cut -d '=' -f2)

# Configure AWS CLI with credentials
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"

mkdir /mnt/efs/fs2/output/hifiasm_"$sample"
cd /mnt/efs/fs2/output/hifiasm_"$sample"

echo "Starting Hifiasm. Go get a coffee or 10."

if [ "$hic_confirm" == "yes" ]; then
	/mnt/efs/fs1/hifiasm/hifiasm -o "$sample".hic.asm -t "$cpu_choice" --hg-size "$genome_size" --h1 /home/"$instance_build"/"$hic1".fastq.gz --h2 /home/"$instance_build"/"$hic2".fastq.gz /home/"$instance_build"/combined.fastq 2> "$sample".log
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

	quast --large --no-snps --plots-format png -t "$cpu_choice" "$sample".primary.fasta "$sample".hap1.fasta "$sample".hap2.fasta

	echo "QUAST Finished."

	conda deactivate

	if [ ! -d ~/miniconda3/envs/busco ]; then
		cp /mnt/efs/fs1/resources/busco_share.yml .
		conda env create --file busco_share.yml
	fi

	conda activate busco

	echo "Starting BUSCO."

	busco -i "$sample".primary.fasta --auto-lineage-euk -o "$sample".primary_out -m genome -c "$cpu_choice"
	busco -i "$sample".hap1.fasta --auto-lineage-euk -o "$sample".hap1_out -m genome -c "$cpu_choice"
	busco -i "$sample".hap2.fasta --auto-lineage-euk -o "$sample".hap2_out -m genome -c "$cpu_choice"

	echo "BUSCO Finished."

	conda deactivate
	
else

	/mnt/efs/fs1/hifiasm/hifiasm -o "$sample".asm -t "$cpu_choice" --hg-size "$genome_size" /home/"$instance_build"/combined.fastq 2> "$sample".log
	
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

	quast --large --no-snps --plots-format png -t "$cpu_choice" "$sample".primary.fasta "$sample".hap1.fasta "$sample".hap2.fasta

	echo "QUAST Finished."

	conda deactivate

	if [ ! -d ~/miniconda3/envs/busco ]; then
		cp /mnt/efs/fs1/resources/busco_share.yml .
		conda env create --file busco_share.yml
	fi

	conda activate busco

	echo "Starting BUSCO."

	busco -i "$sample".primary.fasta --auto-lineage-euk -o "$sample".primary_out -m genome -c "$cpu_choice"
	busco -i "$sample".hap1.fasta --auto-lineage-euk -o "$sample".hap1_out -m genome -c "$cpu_choice"
	busco -i "$sample".hap2.fasta --auto-lineage-euk -o "$sample".hap2_out -m genome -c "$cpu_choice"

	echo "BUSCO Finished."
	conda deactivate
fi

mkdir -p "$client"/"$sample"/Assembly
mkdir -p "$client"/"$sample"/QC/quast
mkdir -p "$client"/"$sample"/QC/busco

cp "$sample".primary.fasta "$sample".hap1.fasta "$sample".hap2.fasta "$client"/"$sample"/Assembly/.

cp quast_results/latest/* "$client"/"$sample"/QC/quast/.
cp "$sample".primary_out/*.txt "$sample".hap1_out/*.txt "$sample".hap2_out/*.txt "$client"/"$sample"/QC/busco/.

zip -r Intermediate_files.zip busco_downloads "$sample".primary_out "$sample".hap1_out "$sample".hap2_out quast_results *.*

mkdir -p "$client"/"$sample"/Intermediate_files && mv Intermediate_files.zip "$client"/"$sample"/Intermediate_files/.

aws s3 cp --recursive /mnt/efs/fs2/output/hifiasm_"$sample"/"$client"/ s3://hifiasm-out/"$client"/

if [ -e "$sample".asm.bp.p_ctg.gfa ]; then
	aws ec2 stop-instances --instance-ids "$instanceid"
fi