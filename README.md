<h1 align="center">GLPI - IT Asset Management</h1>

<p align='justify'>

<a href="https://glpi-project.org">GLPI</a> - is an open source IT Asset Management, issue tracking system and service desk system. This software is written in PHP and distributed as open-source software under the GNU General Public License.

GLPI is a web-based application helping companies to manage their information system. The solution is able to build an inventory of all the organization's assets and to manage administrative and financial tasks. The system's functionalities help IT Administrators to create a database of technical resources, as well as a management and history of maintenances actions. Users can declare incidents or requests (based on asset or not) thanks to the Helpdesk feature.
</p>

- [GLPI Docker Image](#glpi-docker-image)
- [Install GLPI docker container](#install-glpi-docker-container)
  - [Setup timezone](#setup-timezone)

## GLPI Docker Image
Image is based on [Alpine 3.17](https://hub.docker.com/repository/docker/johann8/bacularis/general)

| pull | size | version | platform |
|:---------------------------------:|:----------------------------------:|:--------------------------------:|:--------------------------------:|
| ![Docker Pulls](https://img.shields.io/docker/pulls/johann8/alpine-glpi?style=flat-square) | ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/johann8/alpine-glpi/latest) | [![](https://img.shields.io/docker/v/johann8/alpine-glpi?sort=date)](https://hub.docker.com/r/johann8/alpine-glpi/tags "Version badge") | ![](https://img.shields.io/badge/platform-amd64-blue "Platform badge") |

## Install GLPI docker container
- create folders

```bash
DOCKERDIR=/opt/glpi
mkdir -p ${DOCKERDIR}/data/{glpi,crond,mariadb}
mkdir -p ${DOCKERDIR}/data/glpi/{files,plugins,config}
mkdir -p ${DOCKERDIR}/data/crond/{2min,5min,hourly,daily}
mkdir -p ${DOCKERDIR}/data/mariadb/{dbdata,socket,config}
chown -R 100:101 ${DOCKERDIR}/data/glpi/*
cd ${DOCKERDIR}
tree -d -L 5 ${DOCKERDIR}
```

- Download config files
```bash
DOCKERDIR=/opt/glpi
cd ${DOCKERDIR}
wget https://raw.githubusercontent.com/johann8/alpine-glpi/master/docker-compose.yml
wget https://raw.githubusercontent.com/johann8/alpine-glpi/master/docker-compose.override.yml
wget https://raw.githubusercontent.com/johann8/alpine-glpi/master/.env
```
- Customize variable in .env file
- Run `GLPI` docker container
```bash
DOCKERDIR=/opt/glpi
cd ${DOCKERDIR}
docker-compose up -d

# show logs
docker-compose logs

# show running containers
docker-compose ps
```
- Go to http://glpi.mydomain.de
- Enter the database connection details as shown in the picture
![Connect to Database](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Setup_01.PNG)

### Setup timezone
