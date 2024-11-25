<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>


<h3 align="center">An AGRF repository for manipulating, assembling and analysing HiFi data in AWS</h3>

Table of contents
=================

<!--ts-->
* [Getting Started](#Getting-Started)
  * [Prerequisites](#Prerequisites)
  * [Installation](#Installation)
* [How to Run](#How-to-run)
  * [Rsync your data](#rsyncing-your-data-across-to-the-aws-instance)
  * [Hifiasm](#job-1---hifiasm-assembly)
  * [Pool Party 16S](#job-2---pool-party-16S)
  * [Pool Party ITS](#job-3---pool-party-ITS)
  * [Hifiasm-meta](#Job-4---Hifiasm-meta:-a-metagenome-fork-of-hifiasm)
* [One liners that you might find useful](#one-liners-that-might-come-in-handy)

<!--te-->

<!-- GETTING STARTED -->

## <h3 align="center">Getting Started</h3>

Simply pull this repository into the AWS instance to have the most up-to-date copies of the scripts available. The AWS Instances are maintained through AMI's separately, and should always be compatible (and work out of the box).

### <h3 align="center">Prerequisites</h3>

All workflows now run on the following AMI:
  ```
  16S Nextflow 1Tb attached
  ```

Your username to connect will be ec2-user.

### <h3 align="center">Installation</h3>

1. Turn on and log into AMI as per the SOP.

2. Clone the repo into the home directory (/home/ec2-user/). If you do this immediately after logging into the instance, you'll already be here.

   ```sh
   git clone https://github.com/roylejw/PacBio-related-scripts.git
   ```
   
3. Filezilla/rsync all files directly into the home directory - no need to use EFS storage (it will slow you down). The script will yell at you if your files aren't here.

**I recommend you run all jobs in a screen**. This will avoid your PuTTY window timing out and you losing your assembly progress. To do this, simply type ```screen ``` and press enter. If you are unfamiliar with the use of screen, [the manual can be found here](https://www.gnu.org/software/screen/manual/screen.html#Getting-Started). 

**For a quick cheatsheet**:
- To detach from the screen, press CTRL + A, then CTRL + D.
- To reattach to the screen to check the progress of the job, type ```screen -R```. 
  - Sometimes, this throws a fit and won't re-attach (usually if multiple sessions exist). If so, type ```screen -l``` to see a list of screens, and then type ```screen -x pid.tty.host```, where pid.tty.host is the appended name in the screen list. 


<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- USAGE EXAMPLES -->
## <h3 align="center">How To Run</h3>
### <h3 align="center">Rsyncing your data across to the AWS instance</h3>

Before running any job, you need to get the data onto the AWS instance. To do this, you will need:
- Your data on our local server. Ideally in one folder but you can do this per file if you want. 
- A running AWS instance, and its IPv4 name. 
  - The name will look something like this: ec2-12-345-678-910.ap-southeast-2.compute.amazonaws.com

To rsync your data, log into our local server and run this command, replacing quoted variables with relevant information:

```sh
 rsync -av --progress -e 'ssh -i /home/smrtanalysis/amazon_ssh/EC2.pem' "$PATH/TO/YOUR/FILENAME/file".bam "$USERNAME"@"$AWS-INSTANCE-NAME":/home/"$USERNAME"
 ```
 - "$USERNAME" will usually be ec2-user, depending on your workflow and instance setup
 - AWS instance name can be found on AWS EC2 instances page

 
Things to consider:
- Giving a hard file name (eg. /opt/staging/CAGRF12345/reads.bam) will sync this file only
- If you want to sync the contents of a folder but want them immediately compatible with the scripts, leave a trailing ```/``` (eg. /opt/staging/CAGRF12345/). This will sync the contents directly into the home directory.
- If you want to sync things from AWS back, flip the command (AWS path before local server path). 

If you'd prefer, you can also use Filezilla to move files around. This makes transferring the details.tsv and contracts.txt a breeze for the 16S pipeline. Just use the instance IPv4 name in the host box (prefixed with sftp://), and the correct username (ec2-user or ubuntu) in the username. You don't need a password or port. 

### <h3 align="center">Job #1 - Hifiasm assembly</h3>

To run an automated Hifiasm assembly, run the master script and select option 1. This will run a hifiasm assembly job with automatic QUAST and BUSCO QC. BUSCO is set to auto-linage assessment, through the ```auto-lineage-euk``` command. This automated script will find and combine all sequencing files in the home directory, and requires either a bam, or fastq.gz input. The output is placed in AWS S3 storage, accessible at ```s3://hifiasm-out/```.

Hifiasm memory requirements scale with input HiFi read size. For a single 90Gb HiFi readset, use an instance with 100+Gb RAM. Scale up if more reads are given. 

  ```sh
  bash PacBio-related-scripts/master.bash
  
  >1
  ```

### <h3 align="center">Job #2 - Pool party 16S</h3>

To run a pool party job, first ensure you have the PacBio tools AMI AND Nextflow AMI running. The Nextflow AMI needs to be running on an m5.xlarge on demand instance. You will need the following files in the home directory to start a pool party run:
- The sequencing file (bam, fastq.gz or fastq all acceptable inputs. **Must be one file**)
- A filled-in copy of the details.tsv found in the resources folder. Must be named details.tsv
  - To use the pool column correctly - give them unique names (I use sample names) if sequence depth is high, or they are complex samples (soil). If non-complex samples, or low depth, they can be pooled by the condition given to us (match the metadata column). 
- A text file with each of the contract IDs you wish to analyse in this run. Must be named contracts.txt

If you know there is a complex batch within the pool, ensure you analyze it seperately. Give it a different batch name, contracts.txt and details.tsv for complex batches, and you can run them as a separate batch in step two from the same combined Hifi data. 

  ```sh
  bash PacBio-related-scripts/master.bash
  
  >3
  ```
The output will be placed in the EFS pool party output, separated by contracts needed to be sent out: ```/mnt/efs/fs2/pool_party/YOUR_BATCH/```. It is also synced to the 16s-out S3 bucket.

All credit for the creation of the 16S Workflow goes to Khi Pin and the PacBio team. An original version of the pipeline [can be found here](https://github.com/PacificBiosciences/pb-16S-nf). The version of the main Nextflow workflow uploaded here (found in the resources folder) is edited specifically to work on AWS in our workspace.   

### <h3 align="center">Job #3 - Pool party ITS</h3>

To run a pool party job, first ensure you have the PacBio tools AMI AND Nextflow AMI running. The Nextflow AMI needs to be running on an m5.xlarge on demand instance. You will need the following files in the home directory to start a pool party run:
- The sequencing file (bam, fastq.gz or fastq all acceptable inputs. **Must be one file**)
- A filled-in copy of the details.tsv found in the resources folder. Must be named details.tsv
  - The Pool column is not available to use in ITS analysis - you can fill it out, but it has no functionality. 
- A text file with each of the contract IDs you wish to analyse in this run. Must be named contracts.txt

  ```sh
  bash PacBio-related-scripts/master.bash
  
  >3
  ```
The output will be placed in the EFS pool party output, separated by contracts needed to be sent out: ```/mnt/efs/fs2/pool_party_ITS/YOUR_BATCH/```. It is also synced to the its-out S3 bucket.

All credit for the original creation of the 16S Workflow goes to Khi Pin and the PacBio team. An original version of the pipeline [can be found here](https://github.com/PacificBiosciences/pb-16S-nf). The version of the main Nextflow workflow uploaded here (found in the resources folder) is edited specifically to work on AWS in our workspace, and to account for changes required to work with a full length ITS read.   

### <h3 align="center">Job #4 - Hifiasm-meta: a metagenome fork of hifiasm</h3>

To run an automated Hifiasm metagenome assembly, run the master script and select option 4. This will run the metagenome fork of hifiasm assembly, but will skip the automatic QUAST and BUSCO QC that occurs in the normal hifiasm job. The input to this job is a single bam, or single fastq.gz file. Currently it is unable to take in multiple SMRT cells of data (you can manually combine these prior to running). The output is placed in AWS S3 storage, accessible at ```s3://hifiasm-out/```.

Hifiasm memory requirements scale with input HiFi read size. For a single 90Gb HiFi readset, use an instance with 100+Gb RAM. Scale up if more reads are given. Typically, an R5ad.16xlarge is the best bang for buck at this scale, and very rarely drops out (<5%)

  ```sh
  bash PacBio-related-scripts/master.bash
  
  >4
  ```

### <h3 align="center">One-liners that might come in handy</h3>

Iteratively move into SMRTlink job folders, compress & rename with the job ID for easy syncing to local storage (jobs.txt is a list of jobID files in SMRTLInk (ie. 000000130). Then, on our server, name them per the client sample ID, link their hifi data, and rename the data. As well as the jobs.txt file, you will need a list of edited job ID (eg. 601) + name of sample (eg. CAGRF12345_Assembly1).

```sh
cd /pacbio-root/software/pacbio-software/smrtlink/userdata/jobs_root/0000/0000000
rm -rf temp/
rm jobs.txt
nano jobs.txt ##(and right-click paste the column of job IDs [easiest in excel])##
mkdir temp && cat jobs.txt | while read f || [[ -n $f ]]; do cd "$f"; ls -la; tar -hcvf "$f".tar.gz outputs ; mv "$f".tar.gz ../temp/. ; cd ../ ; done
cd temp/
rename 0000000 '' *

## Open new putty terminal, connect to Bris server

#CAGRF needs to be replaced with your code#
mkdir /opt/staging/CAGRF/Assemblies && cd /opt/staging/CAGRF/Assemblies
rsync -av --progress -e 'ssh -i /home/smrtanalysis/amazon_ssh/smrtlink.pem' ec2-user@ec2-52-62-201-134.ap-southeast-2.compute.amazonaws.com:/pacbio-root/software/pacbio-software/smrtlink/userdata/jobs_root/0000/0000000/temp .
nano rename.txt ##(and right-click paste the column 1 (Job IDs) + column 2 (sample name - eg CAGRF12345_Assembly1 )##
cat rename.txt | while IFS=$'\t', read orig new; do mv "$orig".tar.gz "$new".tar.gz; done

```



If you find weird characters in the file names (eg. '$\r ' or \n's), use this to remove them (replace the character with whatever the file is:
```sh
find -name $'*\r*' -exec rename  $'s|\r| |g' '{}' \;
```

To then remove any spaces in the filename afterwards:
```sh
			for file in *\ *; do
				new_file=${file// /}
				mv "$file" "$new_file"
			done
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## <h3 align="center">Contact</h3>

Jack Royle <br />
Email: jack.royle@agrf.org.au   <br />    [![LinkedIn][linkedin-shield]][linkedin-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/github_username/repo_name.svg?style=for-the-badge
[contributors-url]: https://github.com/github_username/repo_name/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/github_username/repo_name.svg?style=for-the-badge
[forks-url]: https://github.com/github_username/repo_name/network/members
[stars-shield]: https://img.shields.io/github/stars/github_username/repo_name.svg?style=for-the-badge
[stars-url]: https://github.com/github_username/repo_name/stargazers
[issues-shield]: https://img.shields.io/github/issues/github_username/repo_name.svg?style=for-the-badge
[issues-url]: https://github.com/github_username/repo_name/issues
[license-shield]: https://img.shields.io/github/license/github_username/repo_name.svg?style=for-the-badge
[license-url]: https://github.com/github_username/repo_name/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/jackroyle1
[product-screenshot]: images/screenshot.png
[Next.js]: https://img.shields.io/badge/next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white
[Next-url]: https://nextjs.org/
[React.js]: https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB
[React-url]: https://reactjs.org/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com 
