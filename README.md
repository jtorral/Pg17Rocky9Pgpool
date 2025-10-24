# rocky9-pg17-pgpool  
  
  
This repo includes what is necessary to build a Rocky Linux 9 image with Postgres 17 and Pgpool. There are some additional packages included as well. It is a lighter footprint than the original bundle created which included many other packages  
.  
  
So if you need to run Postgres 17 and PgPool, this is a good starting container which has a lot of pre-configured settings to make like easy for you.  
  
**Note**: Currently, I have not not created a version for ARM architecture. That will come next.  
  
  
  
## Quick start  
  
  
  
### 1. Docker Image  
  
To create the Docker image, clone the repository and run the `docker build` command. This command builds an image tagged as **rocky9-pg17-pgpool** from the `Dockerfile` in the local directory.  
  
docker build -t rocky9-pg17-pgpool .  
  
  
Once the image is created, you can build out an environment by following the basic docker run commands described in this particular repo of Pgpool and Watchdog.  
  
  
[Ultimage guide to Pgpool and Watchdog](https://github.com/jtorral/pgpoolTutorial/blob/main/WATCHDOG.md)

**NOTE:**

I have added  the file [build-docker-env.md](https://github.com/jtorral/Pg17Rocky9Pgpool/blob/main/build-docker-env.md) which is a way of managing the docker deploys. It's a poor man's docker-compose written in bash with specific features.

This simplifies the builds.
