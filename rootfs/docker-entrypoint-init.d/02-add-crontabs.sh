#!/bin/sh -e

echo "Starting 02-add-crontabs.sh..."
echo "# do daily/weekly/monthly maintenance" > /etc/crontabs/root
echo "# min   hour    day     month   weekday command" >> /etc/crontabs/root
echo "*/2     *       *       *       *       run-parts /etc/periodic/2min" >> /etc/crontabs/root
echo "*/5     *       *       *       *       run-parts /etc/periodic/5min" >> /etc/crontabs/root
echo "*/15    *       *       *       *       run-parts /etc/periodic/15min" >> /etc/crontabs/root
echo "*/30    *       *       *       *       run-parts /etc/periodic/30min" >> /etc/crontabs/root
echo "0       *       *       *       *       run-parts /etc/periodic/hourly" >> /etc/crontabs/root
echo "0       2       *       *       *       run-parts /etc/periodic/daily" >> /etc/crontabs/root
echo "0       3       *       *       6       run-parts /etc/periodic/weekly" >> /etc/crontabs/root
echo "0       5       1       *       *       run-parts /etc/periodic/monthly" >> /etc/crontabs/root
echo " " /etc/crontabs/root
echo "# GLPI - Run autojobs" >> /etc/crontabs/root
echo "*/2     *       *       *       *       root /usr/bin/php -c /etc/php.ini /var/www/glpi/front/cron.php" >> /etc/crontabs/root
echo " " >> /etc/crontabs/root
echo "# Run GLPI Database backup" >> /etc/crontabs/root
echo "0       1       *       *       *        root /backup.sh" >> /etc/crontabs/root
crontab -l
