#!/bin/sh -e

# set variables
PHP_VERSION=81

# run main
echo "Starting 02-add-crontabs.sh..."
echo
echo "+-----------------------------------+"
echo "|          Setting Crontab          |"
echo "+-----------------------------------+"
echo
echo "# do hourly/daily/weekly/monthly maintenance" > /etc/crontabs/root
echo "# min   hour    day     month   weekday command" >> /etc/crontabs/root
echo "#*/5     *       *       *       *       run-parts /etc/periodic/5min" >> /etc/crontabs/root
echo "#*/15    *       *       *       *       run-parts /etc/periodic/15min" >> /etc/crontabs/root
echo "#*/30    *       *       *       *       run-parts /etc/periodic/30min" >> /etc/crontabs/root
echo "0       *       *       *       *       run-parts /etc/periodic/hourly" >> /etc/crontabs/root
echo "0       2       *       *       *       run-parts /etc/periodic/daily" >> /etc/crontabs/root
echo "0       3       *       *       6       run-parts /etc/periodic/weekly" >> /etc/crontabs/root
echo "0       4       1       *       *       run-parts /etc/periodic/monthly" >> /etc/crontabs/root
echo " " >> /etc/crontabs/root
echo "# GLPI - Run autojobs" >> /etc/crontabs/root
echo "*/2     *       *       *       *       /usr/bin/php${PHP_VERSION} -c /etc/php${PHP_VERSION}/php.ini /var/www/glpi/front/cron.php" >> /etc/crontabs/root
#echo " " >> /etc/crontabs/root
#echo "# Run GLPI Database backup" >> /etc/crontabs/root
#echo "0       1       *       *       *       /bin/backup.sh" >> /etc/crontabs/root
crontab -l
