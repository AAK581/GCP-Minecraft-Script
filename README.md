# GCP-Minecraft-Script
A bash script that, when run through the Google Cloud shell, creates a Minecraft version 1.20.2 server and sets up another script that backs up the game's data every 4 hours to a storage bucket

How to use:
- Create an environment variable for your project name, which is crucial, by typing this:
```
export PROJECT_ID="your project's id, without the double quotations"
```

- Create an environment variable for your backup bucket's name, by typing this:
```
export YOUR_BUCKET_NAME="your desired bucket name, without the double quotations as well"
```

- Authenticate yourself:
```
gcloud auth login
```

- Set the script as an executable by typing this:
```
chmod u+x mcServer.sh
```

- Run the script by typing:
```
./mcServer.sh
```

- In case you get an error that says: "/bin/bash^M: bad interpreter: No such file or directory", type:
```
sed -i -e 's/\r$//' scriptname.sh
```

- After the sever has run, you can go open a new shell tab and type:
```
gcloud compute ssh mc-server --zone=us-central1-c --command="sudo screen -r"
```
This way you can type commands into the server itself
