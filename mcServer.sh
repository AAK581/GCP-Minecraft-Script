#!/bin/bash

#Set project
gcloud config set project $PROJECT_ID
#Setting a region
gcloud compute project-info add-metadata \
    --metadata google-compute-default-region=us-central1,google-compute-default-zone=us-central1-c
#Creating a VPC network
gcloud compute networks create mc-network --subnet-mode=auto
#Creating the firewall rule
gcloud compute firewall-rules create mc-firewall --network=mc-network --allow=tcp:22,tcp:3389,icmp,tcp:25565,tcp:80 --target-tags=minecraft-server
#Create an external static IP address
gcloud compute addresses create mc-server-address --region=us-central1
#Set it to a variable
mcIP=$(gcloud compute addresses describe mc-server-address --region=us-central1 | grep "address: " | tr -d -c 0-9\.)
#Creating the Vm
gcloud compute instances create mc-server --zone=us-central1-c --address=$mcIP --machine-type=e2-standard-4 --scopes=cloud-platform --network=mc-network --tags=minecraft-server
#Creating a local SSD disk
gcloud compute disks create mc-disk --size=50 --type=pd-ssd --zone=us-central1-c
#Attaching the disk to the Vm
gcloud compute instances attach-disk mc-server --disk=mc-disk --zone=us-central1-c
#Formatting the disk
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb"
#Creating a minecraft folder to use as a mount point
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo mkdir -p minecraft"
#Mounting
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo mount -o discard,defaults /dev/sdb minecraft"
#Updating
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo apt-get update"
#Installing JRE
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo apt install openjdk-17-jre-headless"
#Going into the Minecraft directory
gcloud compute ssh mc-server --zone=us-central1-c --command="cd minecraft/"
#Downloading the server software
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo wget https://piston-data.mojang.com/v1/objects/5b868151bd02b41319f54c8d4061b8cae84e665c/server.jar"
#Installng the server
echo "Starting server"
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo java -Xmx1024M -Xms1024M -jar server.jar nogui"
#Checking the EULA
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo sed -i 's/false/true/g' eula.txt"
#To allow anybody
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo sed -i 's/online-mode=true/online-mode=false/g' server.properties"
#To start the server using a screen
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo screen -d -m -L -S mcs bash -c 'java -Xmx1024M -Xms1024M -jar server.jar nogui'"
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo screen -list"
echo "The server is running, please use a 1.20.2 client"
#To create a storage bucket for backup
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo gsutil mb gs://$YOUR_BUCKET_NAME-mc-backup"
#Creating the backup file
gcloud compute ssh mc-server --zone=us-central1-c --command="echo 'sudo screen -r mcs -X stuff "/save-all\n/save-off\n"' >> backup.sh"
gcloud compute ssh mc-server --zone=us-central1-c --command="echo '/usr/bin/gsutil cp -R ${BASH_SOURCE%/*}/world gs://${YOUR_BUCKET_NAME}-minecraft-backup/$(date "+%Y%m%d-%H%M%S")-world' >> backup.sh"
gcloud compute ssh mc-server --zone=us-central1-c --command="echo 'sudo screen -r mcs -X stuff "/save-on\n"' >> backup.sh"
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo chmod u+x backup.sh"
#Automating the backup file to run every 4 hours
gcloud compute ssh mc-server --zone=us-central1-c --command="(crontab -l; echo '0 */4 * * * /home/minecraft/backup.sh' ) | crontab -"
