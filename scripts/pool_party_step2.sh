#!/bin/sh

### Housekeeping - no need to change ###
EFS="/mnt/efs/fs2/pool_party"
TMPDIR="/mnt/efs/fs1/temp"
contracts=""$EFS"/"$run_number"/"contracts.txt""


cd "$TMPDIR"

while read client || [[ $client ]]; do

	cd "$client"
	rm report_"$client"_Analysis/*
	if [[ "$skipnb" == "yes" ]]; then
		nextflow run /mnt/efs/fs1/new_16s/pb-16S-nf/main.nf --input sample.tsv --metadata metadata.tsv --dada2_cpu 94 --vsearch_cpu 94 --skip_nb true -profile docker --outdir "$client"_Analysis -bucket-dir 's3://16s-pipeline/temp' -resume
	else
		nextflow run /mnt/efs/fs1/new_16s/pb-16S-nf/main.nf --input sample.tsv --metadata metadata.tsv --dada2_cpu 94 --vsearch_cpu 94 -profile docker --outdir "$client"_Analysis -bucket-dir 's3://16s-pipeline/temp' -resume
	fi
	
	### Create Analysis Directory, move files out to EFS & edit HTML ###
	
	mkdir "$EFS"/"$run_number"/"$client"
	cp -rL "$client"_Analysis/ "$EFS"/"$run_number"/"$client"/
	cd "$EFS"/"$run_number"/"$client"/
	mv "$client"_Analysis/ Analysis/
	cd Analysis/results
	cp "$EFS"/../../fs1/resources/project_info.txt .
	cp "$EFS"/../../fs1/resources/agrf_logo.txt .
	head -n 3394 visualize_biom.html > top.html
	sed -n '3395,3407p' visualize_biom.html > pre-info.html
	sed -n '3408,3596p' visualize_biom.html > post-info.html
	sed -i "s/ID: /ID: $client/g" project_info.txt
	sed -i "s/date: /date: $(date)/g" project_info.txt
	#sed -i "s/Client: /Client: $client/g" project_info.txt
	cat top.html agrf_logo.txt pre-info.html project_info.txt post-info.html > report.html
	mv report.html "$EFS"/"$run_number"/"$client"/16S_analysis_report.html
	rm pre-info* post-info* project_info* agrf_logo* top*
	cd "$EFS"/"$run_number"/"$client"/
	touch "$EFS"/"$run_number"/"$client"/run_complete
	cd "$TMPDIR"
done < "$contracts"

aws ec2 stop-instances --instance-ids "$instance"

