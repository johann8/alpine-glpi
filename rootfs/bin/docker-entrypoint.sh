#!/bin/sh

# set variables
INSTALL_WEB_ROOT_PATH="/var/www/glpi"
WEB_ROOT_PATH="/var/www/glpi/public"

# add functions
shutdown() {
  echo "shutting down container"

  # first shutdown any service started by runit
  for _srv in $(ls -1 /etc/service); do
    sv force-stop $_srv
  done

  # shutdown runsvdir command
  kill -HUP $RUNSVDIR
  wait $RUNSVDIR

  # give processes time to stop
  sleep 0.5

  # kill any other processes still running in the container
  for _pid  in $(ps -eo pid | grep -v PID  | tr -d ' ' | grep -v '^1$' | head -n -6); do
    timeout -t 5 /bin/sh -c "kill $_pid && wait $_pid || kill -9 $_pid"
  done
  exit
}

# JH addded on 12.10.2022
# Function only for GLPI
# Verify folders
VerifyDir () {

  DIR="/var/www/glpi/files/_cron
  /var/www/glpi/files/_dumps
  /var/www/glpi/files/_graphs
  /var/www/glpi/files/_log
  /var/www/glpi/files/_lock
  /var/www/glpi/files/_pictures
  /var/www/glpi/files/_plugins
  /var/www/glpi/files/_rss
  /var/www/glpi/files/_tmp
  /var/www/glpi/files/_uploads
  /var/www/glpi/files/_cache
  /var/www/glpi/files/_sessions
  /var/www/glpi/files/_locales"

  for i in $DIR
  do
    if [ ! -d $i ]
    then
      echo -n "Creating $i dir... "
      mkdir -p $i
      echo "[done]"
    fi
  done
}

# JH addded on 12.10.2022
# Function only for GLPI
# Set permissions
SetPermissions () {
  echo -n "Setting chown in files and plugins... "
  chown -R nginx:nginx /var/www/glpi/files
  chown -R nginx:nginx /var/www/glpi/plugins
  echo "[done]"

}

echo "+----------------------------------------------------------+"
echo "|                                                          |"
echo "|      Welcome to GLPI - IT Asset Management Docker!       |"
echo "|                                                          |"
echo "+----------------------------------------------------------+"
echo
echo "Starting startup scripts in /docker-entrypoint-init.d ..."

for script in $(find /docker-entrypoint-init.d/ -executable -type f); do

    echo >&2 "*** Running: $script"
    $script
    retval=$?
    if [ $retval != 0 ];
    then
        echo >&2 "*** Failed with return value: $?"
        exit $retval
    fi

done
echo "Finished startup scripts in /docker-entrypoint-init.d"

# JH addded on 12.10.2022
# Run function only for GLPI
# ========= Start ==========
VerifyDir
SetPermissions

# Delete installation file "install.php" if glpi is already installed
if [[ -e "/var/www/glpi/config/glpicrypt.key" ]]
then
   echo "+-----------------------------------------------+"
   echo "|       GLPI has already been installed!        |"
   echo "+-----------------------------------------------+"
   echo
   #echo "GLPI has already been installed."
   echo "GLPI installation \"install.php\" file will be deleted."
   echo -n "Deleting \"install.php\" file...               "
   rm -rf /var/www/glpi/install/install.php
   echo "[done]"

   # set www root directory
   echo -n "Setting www root directory...                  "
   sed -i -e "s+###WWW_ROOT_DIRECTORY###+${WEB_ROOT_PATH}+" /etc/nginx/nginx.conf
   echo "[done]"
else
   echo "+-----------------------------------------------+"
   echo "|          GLPI is not installed yet!           |"
   echo "+-----------------------------------------------+"
   echo
   #echo "GLPI is not installed yet."

   # set www install root directory
   echo -n "Setting www install root directory...          "
   sed -i -e "s+###WWW_ROOT_DIRECTORY###+${INSTALL_WEB_ROOT_PATH}+" /etc/nginx/nginx.conf
   echo "[done]"
fi

# Set options into custom.ini
echo "+-----------------------------------------------+"
echo "|   Customizing from environment variables...   |"
echo "+-----------------------------------------------+"
echo
echo -n "Setting \"date.timezone\" into custom.ini...       "
sed -i -e '/date.timezone=/c\date.timezone="'${TZ}'"' /etc/php81/conf.d/custom.ini
echo "[done]"

echo -n "Setting \"date.timezone\" into php.ini...          "
sed -i -e '/;date.timezone =/c\date.timezone = '${TZ}'' /etc/php81/php.ini
echo "[done]"

echo -n "Setting \"upload_max_filesize\" into custom.ini... "
sed -i -e '/upload_max_filesize= /c\upload_max_filesize= '${UPLOAD_MAX_FILESIZE}'' /etc/php81/conf.d/custom.ini
echo "[done]"

echo -n "Setting \"post_max_size\" into custom.ini...       "
sed -i -e '/post_max_size= /c\post_max_size= '${POST_MAX_SIZE}'' /etc/php81/conf.d/custom.ini
echo "[done]"
# ========== END ==========

echo "Starting runit..."
exec runsvdir -P /etc/service &

RUNSVDIR=$!
echo "Started runsvdir, PID is $RUNSVDIR"
echo "wait for processes to start...."

sleep 5
for _srv in $(ls -1 /etc/service); do
    sv status $_srv
done

# catch shutdown signals
trap shutdown SIGTERM SIGHUP SIGQUIT SIGINT
wait $RUNSVDIR

shutdown
