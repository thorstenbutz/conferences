# Docker exmaple commands

## Setup docker (docker-io/docker-ce) on UBUNTU
Reference: https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-from-a-package

### docker: ubuntu packages // v1.12 (summer 2017) 
    apt-get install docker.io

### Uninstall
    apt-get remove docker docker-engine docker.io

### setup docker: docker.com stable repo
    apt-get install apt-transport-https ca-certificates curl software-properties-common

### Add Docker’s official GPG key fingerprint (9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88)
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    apt-key fingerprint 0EBFCD88

### Add a line to the sources.list file: 
deb [arch=amd64] https://download.docker.com/linux/ubuntu zesty stable

    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    cat /etc/apt/sources.list | grep -i docker
    apt-get update
    apt-get install docker-ce -y

### 1st tests: running docker
    which docker
    docker info
    docker version   # 17.06.x
    systemctl status docker 
    docker ps
    docker run hello-world
    docker run --rm hello-world   # temporary, remove on exit

### Show images
    docker images # or: docker image ls

### Find new images: (official: Updated by the docker team; Automated: autom. build process)
    docker search ubuntu 
    docker search ubuntu -f  "is-official=true"
    docker search ubuntu --filter "is-official=true" --no-trunc

### Run ubuntu as container: 
    docker run ubuntu
    docker run --interactive --tty ubuntu
    docker run -it ubuntu bash

    apt-get update && apt-get install net-tools -y # Inside ubuntu container

    docker start <id>
    docker exec -it <id> bash
    docker stop <id>

    docker run -d --name trick_duck ubuntu bash

### Run centos as container
    docker pull centos
    docker run -d centos 

### Run a webserver as container
    docker pull nginx
    docker run -d -p 80:80 --name donald_duck nginx # Start detached
    docker ps
    docker stop donald_duck
    docker stop <id>

    docker run --name mickey_mouse -d -p 8001:80 nginx
    docker exec -it <id> bash

    cd /usr/share/nginx/html:ro nginx # inside container   
    echo "<h1>Hello World</h1>" > index.html
    docker stop $(docker ps -q)

    docker rm donald_duck
    docker run -d -p 80:80 -v /tmp/html/:/usr/share/nginx/html:ro --name donald_duck nginx # -v: map host folder
    echo "<h1>Constructing ..</h1>" > index.html
    
### Clean up
    docker stop $(docker ps -q)
    docker rm $(docker ps -a -q)

### Measure size
    docker system df -v