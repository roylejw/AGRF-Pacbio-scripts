<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://www.agrf.org.au">
    <img src="logos/logo.png" alt="Logo" width="110" height="100">
  </a>
  &nbsp;
  <a href="https://www.pacb.com">
    <img src="logos/pacbio-logo.PNG" alt="Logo" width="150" height="80">
  </a>
</div>

<h3 align="center">An AGRF repository for manipulating, assembling and analysing HiFi data in AWS</h3>

<!-- GETTING STARTED -->

## <h3 align="center">Getting Started</h3>

Simply pull this repository into the AWS instance to have the most up-to-date copies of the scripts available. The AWS Instances are maintained through AMI's separately, and should always be compatible (and work out of the box).

### <h3 align="center">Prerequisites</h3>

Due to compatability issues, there are two separate AMIs to have running depending on what kind of work you intend on running. 

If you want to run assemblies, demultiplexing, or BAM conversions, you will need to start an instance using the following AMI:
  ```
  PacBio Tools Image
  ```
If you want to run the 16S workflow, or any future Nextflow workflow, you will need to start an instance using the following AMI:
  ```
  16S Nextflow 1Tb attached
  ```

Take note that your username will be different - The Pacbio tools image uses 'ubuntu', whereas the nextflow image uses 'ec2-user'. Keep that in mind when connecting with Putty/Filezilla/etc.

### <h3 align="center">Installation</h3>

1. Turn on and log into AMI as per the SOP.

2. Clone the repo into the home directory (/home/ubuntu/ or /home/ec2-user/). If you do this immediately after logging into the instance, you'll already be here.

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
- A running AWS instance, and its name. 
  - The name will look something like this: ec2-12-345-678-910.ap-southeast-2.compute.amazonaws.com

To rsync your data, log into our local server and run this command, replacing quoted variables with relevant information:

```sh
 rsync -av --progress -e 'ssh -i /home/smrtanalysis/amazon_ssh/EC2.pem' "$PATH/TO/YOUR/FILENAME/file".bam "$USERNAME"@"$AWS-INSTANCE-NAME":/home/"$USERNAME"
 ```
 - "$USERNAME" will either be ubuntu or ec2-user, depending on your workflow
 - AWS instance name can be found on AWS EC2 instances page
 
Things to consider:
- Giving a hard file name (eg. /opt/staging/CAGRF12345/reads.bam) will sync this file only
- If you want to sync the contents of a folder but want them immediately compatible with the scripts, leave a trailing ```/``` (eg. /opt/staging/CAGRF12345/). This will sync the contents directly into the home directory.
- If you want to sync things from AWS back, flip the command (AWS path before local server path). 

### <h3 align="center">Job #1 - Hifiasm assembly</h3>

To run an automated Hifiasm assembly, run the master script and select option 1. This will run a hifiasm assembly job with automatic QUAST and BUSCO QC. BUSCO is set to auto-linage assessment, through the ```auto-lineage-euk``` command. This automated script can handle up to 4 hifi cells at the moment, and requires either a bam, or fastq.gz input. The output is placed in AWS EFS storage, accessible at ```/mnt/efs/fs2/output```.

  ```sh
  bash AGRF-Pacbio-scripts/master.sh
  
  >1
  ```
### <h3 align="center">Job #2 - Demultiplexing</h3>

To run a demultiplex job, run the master script and select option 2. This will demultiplex your hifi data using Lima, rename it and place the output in AWS EFS storage, accessible at ```/mnt/efs/fs2/output``` as fastq files.

You must fill out the barcode csv (a template can be found in the resources folder) with corresponding sample names. If you do not, the script will not be able to rename your files correctly. This must be placed in ```/home/ubuntu``` with the other input files. Please keep the filename the same as those found in the resources folder. 

The input for this job can be either bam, fastq.gz or fastq.

  ```sh
  bash AGRF-Pacbio-scripts/master.sh
  
  >2
  ```  

### <h3 align="center">Job #3 - Pool party pt. 1</h3>

To run a pool party job, first ensure you have the PacBio tools AMI AND Nextflow AMI running. The Nextflow AMI needs to be running on an m5.xlarge on demand instance. You will need the following files in the home directory to start a pool party run:
- The sequencing file (bam, fastq.gz or fastq all acceptable inputs. **Must be one file**)
- A filled-in copy of the details.tsv found in the resources folder. Must be named details.tsv
  - To use the pool column correctly - give them unique names (I use sample names) if sequence depth is high, or they are complex samples (soil). If non-complex samples, or low depth, they can be pooled by the condition given to us (match the metadata column). 
- A text file with each of the contract IDs you wish to analyse in this run. Must be named contracts.txt

If you know there is a complex batch within the pool, ensure you analyze it seperately. Give it a different batch name, contracts.txt and details.tsv for complex batches, and you can run them as a separate batch in step two from the same combined Hifi data. 

  ```sh
  bash AGRF-Pacbio-scripts/master.sh
  
  >3
  ```
  
### <h3 align="center">Job #4 - Pool party pt. 2</h3>

Simply clone in this repo and run job #4. If these are non-complex batches, answer 'no' to the NB classification question. If these are all complex, answer yes and it will skip the Naive-Bayes classification step.

  ```sh
  bash AGRF-Pacbio-scripts/master.sh
  
  >4
  ```

The output will be places in the EFS pool party output, separated by contracts needed to be sent out ```/mnt/efs/fs2/pool_party/YOUR_BATCH/```

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
