#!/bin/sh

### NOTES ###

<< COMMENT

Requires AVX2 instance with significant memory. This can require moving out of Sydney and into another location (Singapore). Having good success on an r6a.24xlarge spot instance (~ $1USD/hour).
Have split samples into top 30 scaffolds - retains all BUSCO metrics, while removing a lot of small contigs that slow down the assembly. Requires little set-up once instance is started.
Runs on a 'samples.txt' - first column = sample name (eg. H01), second column = filepath (eg. /home/ec2-user/samples/H01.fasta). 

!!! NEED TO INSTALL DOCKER FIRST !!! This involves logging in and out of the instance, commands are here:
```
sudo yum install -y docker
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
sudo chmod 666 /var/run/docker.sock

LOG OUT AND BACK IN (close putty, log back in)

docker info
```
This should correctly display a bunch of info (if you don't get an error it was successful)

COMMENT

sudo yum install -y amazon-efs-utils pip python3 git
python3 -m pip install virtualenv

aws configure

sudo mkdir /mnt/efs
if [ ! -d /mnt/efs/fs2/ ]; then
	sudo mkdir /mnt/efs/fs2
fi
sudo mount -t efs -o tls fs-018fdbc24abe8afd5:/ /mnt/efs/fs2

if [ ! -d /mnt/efs/fs1/ ]; then
	sudo mkdir /mnt/efs/fs1
fi
sudo mount -t efs -o tls fs-0d05585280ab96dd4:/ /mnt/efs/fs1

git clone https://github.com/ComparativeGenomicsToolkit/cactus.git --recursive
cd cactus
virtualenv -p python3 cactus_env
echo "export PATH=$(pwd)/bin:\$PATH" >> cactus_env/bin/activate
echo "export PYTHONPATH=$(pwd)/lib:\$PYTHONPATH" >> cactus_env/bin/activate
source cactus_env/bin/activate
python3 -m pip install -U setuptools pip wheel
python3 -m pip install -U .
python3 -m pip install -U -r ./toil-requirement.txt

cactus-pangenome jobstore /home/ec2-user/samples.txt --outDir pangenome_test --outName senecio --reference H01 --vcf --gbz --gfa --giraffe --chrom-vg --odgi --chrom-og --viz --draw
