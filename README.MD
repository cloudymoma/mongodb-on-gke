# 0. Setup environment
```
gcloud auth login
gcloud config set project <PROJECT_ID>
```

# 1. Clone this repo to your local
```
git clone https://github.com/cloudymoma/mongodb-on-gke.git
cd mongodb-on-gke
./setup.sh
# Input GKE cluster name, cluster domain name for MongoDB, machine type for GKE node.
```
<img src="screenshot/1.png">

#2. Wait for about 20 minutes.

Go to GCP console, check the GKE cluster, and mongo DB in namespace `mongodb`
<img src="screenshot/2.png">
<img src="screenshot/3.png">
<img src="screenshot/4.png">
<img src="screenshot/5.png">
<img src="screenshot/6.png">
