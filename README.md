<h1 align="center">GLPI - IT Asset Management</h1>

<p align='justify'>

<a href="https://glpi-project.org">GLPI</a> - is an open source IT Asset Management, issue tracking system and service desk system. This software is written in PHP and distributed as open-source software under the GNU General Public License.

GLPI is a web-based application helping companies to manage their information system. The solution is able to build an inventory of all the organization's assets and to manage administrative and financial tasks. The system's functionalities help IT Administrators to create a database of technical resources, as well as a management and history of maintenances actions. Users can declare incidents or requests (based on asset or not) thanks to the Helpdesk feature.
</p>

- [GLPI Docker Image](#glpi-docker-image)
- [Install GLPI docker container](#install-glpi-docker-container)
  - [Setup Timezone](#setup-timezone)
  - [Setup General](#setup-general)
  - [Setup Plugins via CLI](#setup-plugins-via-cli)
  - [Setup OCS Inventory NG](#setup-ocs-inventory-ng)
  - [Setup Mailgate](#setup-mailgate)
  - [Setup Memcached](#setup-memcached)

## GLPI Docker Image
Image is based on [Alpine 3.20](https://hub.docker.com/repository/docker/johann8/alpine-glpi/general)

| pull | size | version | platform | alpine version |
|:---------------------------------:|:----------------------------------:|:--------------------------------:|:--------------------------------:|:--------------------------------:|
| ![Docker Pulls](https://img.shields.io/docker/pulls/johann8/alpine-glpi?logo=docker&label=pulls&style=flat-square&color=blue) | ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/johann8/alpine-glpi/latest?logo=docker&style=flat-square&color=blue&sort=semver) | [![](https://img.shields.io/docker/v/johann8/alpine-glpi?logo=docker&style=flat-square&color=blue&sort=semver)](https://hub.docker.com/r/johann8/alpine-glpi/tags "Version badge") | ![](https://img.shields.io/badge/platform-amd64-blue "Platform badge") | [![Alpine Version](https://img.shields.io/badge/Alpine%20version-v3.20.0-blue.svg?style=flat-square)](https://alpinelinux.org/) |

## Install GLPI docker container
- create folders

```bash
DOCKERDIR=/opt/glpi
mkdir -p ${DOCKERDIR}/data/{glpi,crond,crontabs,mariadb}
mkdir -p ${DOCKERDIR}/data/glpi/{files,plugins,config}
mkdir -p ${DOCKERDIR}/data/crond/{5min,15min,30min,hourly,daily,weekly,monthly}
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
- Choose the database glpi
![Choose Database](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Setup_02.PNG)

- Run through the installation wizard and log in with glpi / glpi
- After logging in the message appears at the top
![First Login](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Setup_03.PNG)

- Log out and restart docker  container
```bash
DOCKERDIR=/opt/glpi
cd ${DOCKERDIR}
docker-compose down && docker-compose up -d

# show logs
docker-compose logs

# show running containers
docker-compose ps
```
- If you see the message like on the picture under Logs `docker-compose logs`, then the installation went through successfully
![First container restart ](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Setup_04.PNG)

- You can configure GLPI now

## Setup Timezone
- First you have to grant the database user `glpi` access to the table `time_zone_name`
```bash
DOCKERDIR=/opt/glpi
cd ${DOCKERDIR}
docker-compose exec glpidb bash

mysql -uroot -p${MARIADB_ROOT_PASSWORD}

MariaDB [mysql]> GRANT SELECT ON `mysql`.`time_zone_name` TO 'glpi'@'%';
MariaDB [mysql]> FLUSH PRIVILEGES;
\q
exit
```
- Then activate timezone in `glpi`
```bash
DOCKERDIR=/opt/glpi
cd ${DOCKERDIR}
docker-compose exec glpi sh
php bin/console database:enable_timezones
exit
```
- Check if everything went well. Log in to the web interface
- Go to: Setup =>General =>Server. You will see: `Timezones seems loaded in database`


## Setup General
- Enable inventory: Go to -> Administration =>Inventory =>Configuration => Enable inventory
- Disable user normal: Go to -> Administration =>Users =>normal =>Set "Active" to No =>Save
- Disable user post-only: Go to -> Administration =>Users =>post-only =>Set "Active" to No =>Save
- Disable user tech: Go to -> Administration =>Users =>tech =>Set "Active" to No =>Save
- Setup Email reciver: Go to -> Setup =>Receivers =>+ ADD => Fill in the form as shown in the picture
![Mail Reciver](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Recivers_Mail_01.PNG)

- Register Account GLPI Network: Go to -> Setup =>Plugins =>Marketplace => Register on GLPI Network and fill your registration key in setup
- Install the following plugins: Go to -> Setup =>Plugins =>Marketplace
![Plugins](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Plugins_01.PNG)

- Store the following Tags: Go to -> Setup =>Dropdowns =>Tag Management => Tags
![Tags](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Tags_01.PNG)

- Store the following Statuses: Go to -> Setup =>Dropdowns =>Common =>Statuses of items
![Statuses](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Status_of_Items_01.PNG)

- Enable Notifications: Go to -> Setup =>Notifications
![Notifications](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Notifications_01.PNG)

## Setup Plugins via CLI
- You can install plugins via CLI (assuming you have registered marketplace)
```bash
DOCKERDIR=/opt/glpi
cd ${DOCKERDIR}
docker-compose exec glpi sh
ALL_PLUGINS="actualtime fields news reports formcreator addressing accounts mreporting moreticket genericobject ocsinventoryng pdf shellcommands tag timelineticket"
for i in ${ALL_PLUGINS}; do
   php bin/console glpi:marketplace:download $i
   bin/console glpi:plugin:install $i -u glpi
   bin/console glpi:plugin:activate $i
   \cp -rf marketplace/$i plugins/
   chown -R nginx:nginx plugins/$i
done
exit
```
## Setup OCS Inventory NG
After installing of OCS Inventory NG plugin it must be configured. If database of `OCS Inventory` is running in the same `docker stack`, then you can use service name (e.g. ocsdb) as host. If `OCS Inventory` database is running in the other `docker stack`, then the database must listen on `port 3306` of host `IP address` and then you enter the `IP address` of docker host as the host.
- Configure OCS Inventory NG plugin: Go to -> Tools => OCS Inventory NG =>Add a OCSNG server =>  Fill in the form as shown in the picture
![OCS Inventory Server](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_OCS_Inventory_01.PNG)

If during the test you see the message like in the picture below, 
![OCS Inventory Message](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_OCS_Inventory_02.PNG)
then you have to change the following setting via the web interface of OCS Inventory:

- Go to: Configuration > General Configuration > Server > TRACE_DELETE = ON
![OCS Inventory Setting](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_OCS_Inventory_03.PNG)

## Setup Mailgate
- Log in to the web interface
- Go to: Setup =>Automatic actions =>mailgate
- Fill in the form as shown in the picture
![Mailgate](https://raw.githubusercontent.com/johann8/alpine-glpi/master/docs/assets/screenshots/GLPI_Mailgate_01.PNG)

## Setup Memcached
If you have memcached docker container in the same stack, you can enable memcached under glpi as follows:
```bash
DOCKERDIR=/opt/glpi
cd ${DOCKERDIR}
docker-compose exec glpi sh
php bin/console glpi:cache:configure --dsn memcached://memcached:11211
exit
```
Enjoy!
