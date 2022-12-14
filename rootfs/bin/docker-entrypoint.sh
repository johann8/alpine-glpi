#!/bin/sh

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

  DIR="/var/www/html/files/_cron
  /var/www/html/files/_dumps
  /var/www/html/files/_graphs
  /var/www/html/files/_log
  /var/www/html/files/_lock
  /var/www/html/files/_pictures
  /var/www/html/files/_plugins
  /var/www/html/files/_rss
  /var/www/html/files/_tmp
  /var/www/html/files/_uploads
  /var/www/html/files/_cache
  /var/www/html/files/_sessions
  /var/www/html/files/_locales"

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
  chown -R nginx:nginx /var/www/html/files
  chown -R nginx:nginx /var/www/html/plugins
  echo "[done]"

}

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

echo "Starting runit..."
exec runsvdir -P /etc/service &

RUNSVDIR=$!
echo "Started runsvdir, PID is $RUNSVDIR"
echo "wait for processes to start...."

sleep 5
for _srv in $(ls -1 /etc/service); do
    sv status $_srv
done

# JH addded on 12.10.2022
# Run function only for GLPI
# ========= Start ==========
VerifyDir
SetPermissions

# Delete installation file "install.php" if glpi is already installed
if [[ -e "/var/www/html/config/glpicrypt.key" ]]
then
   echo "GLPI has already been installed."
   echo "GLPI installation \"install.php\" file will be deleted."
   echo -n "Deleting \"install.php\" file... "
   rm -rf /var/www/html/install/install.php
   echo "[done]"
else
   echo "GLPI is not installed yet."
fi

# Set options into custom.ini
echo -n "Setting \"date.timezone\" into custom.ini..."
sed -i -e '/date.timezone=/c\date.timezone="'${TZ}'"' /etc/php81/conf.d/custom.ini
echo "[done]"

echo -n "Setting \"date.timezone\" into php.ini..."
sed -i -e '/;date.timezone =/c\date.timezone = '${TZ}'' /etc/php81/php.ini
echo "[done]"

echo -n "Setting \"upload_max_filesize\" into custom.ini..."
sed -i -e '/upload_max_filesize= /c\upload_max_filesize= '${UPLOAD_MAX_FILESIZE}'' /etc/php81/conf.d/custom.ini
echo "[done]"

echo -n "Setting \"post_max_size\" into custom.ini..."
sed -i -e '/post_max_size= /c\post_max_size= '${POST_MAX_SIZE}'' /etc/php81/conf.d/custom.ini
echo "[done]"
# ========== END ==========

# catch shutdown signals
trap shutdown SIGTERM SIGHUP SIGQUIT SIGINT
wait $RUNSVDIR

shutdown
