ARG ARCH=

ARG BASE_IMAGE=alpine:3.16

FROM ${ARCH}${BASE_IMAGE}

LABEL Maintainer="Johann H. <email>" \
      Description="Docker container with GLPI based on Alpine Linux."

# set variables
ENV container docker

ENV GLPI_VERSION 10.0.7

ENV GLPI_LANG en_US

ENV MARIADB_HOST mariadb

ENV MARIADB_PORT 3306

ENV MARIADB_DATABASE glpi

ENV MARIADB_USER glpi

ENV MARIADB_PASSWORD glpi

ENV TZ Europe/Berlin

ENV UPLOAD_MAX_FILESIZE 100M 

ENV POST_MAX_SIZE 50M

# Install packages
RUN apk --no-cache add \
        php81 \
        php81-fpm \
        php81-opcache \
        php81-pecl-apcu \
        php81-pecl-memcached \
        php81-mysqli \
        php81-cli \
        php81-ldap \
        php81-sodium \
        php81-bz2 \
        php81-exif \
        php81-imap \
        php81-intl \
        php81-pgsql \
        php81-json \
        php81-openssl \
        php81-curl \
        php81-zlib \
        php81-soap \
        php81-xml \
        php81-fileinfo \
        php81-phar \
        php81-intl \
        php81-dom \
        php81-xmlreader \
        php81-ctype \
        php81-session \
        php81-iconv \
        php81-tokenizer \
        php81-zip \
        php81-simplexml \
        php81-mbstring \
        php81-gd \
        nginx \
        runit \
        curl \
        tzdata \
        # php8-pdo \
        # php8-pdo_pgsql \
        # php8-pdo_mysql \
        # php8-pdo_sqlite \
        # php8-bz2 \
# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
# Remove alpine cache
    && rm -rf /var/cache/apk/* \
# Remove default server definition
    && rm /etc/nginx/http.d/default.conf \
## Make sure files/folders needed by the processes are accessable when they run under the nobody user
#    && chown -R nobody.nobody /run \
     && chown -R nginx.nginx /var/log/php81 \
     && chown -R nginx.nginx /var/lib/nginx \
     && chown -R nginx.nginx /var/lib/php81
     #&& chown -R nobody.nobody /var/log/nginx

# Add configuration files
#COPY --chown=nobody rootfs/ /
COPY rootfs/ /

# Set php option
RUN echo "session.cookie_httponly = On" >> /etc/php81/conf.d/custom.ini

# create crond folder
RUN mkdir -p /etc/periodic/2min \
    && mkdir -p /etc/periodic/5min \
    && mkdir -p /etc/periodic/30min

# Set timezone
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime

# Install GLPI
ADD https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz /tmp/

RUN tar -zxf /tmp/glpi-${GLPI_VERSION}.tgz -C /tmp/ \
 && mv /tmp/glpi/* /var/www/html/ \
 && chown -R nginx:nginx /var/www/html \
 && rm -rf /tmp/glpi-${GLPI_VERSION}.tgz

VOLUME [ "/var/www/html/files", "/var/www/html/plugins" ]


## Switch to use a non-root user from here on
#USER nobody

# Add application
WORKDIR /var/www/html

# Expose the port nginx is reachable on
EXPOSE 8080

# Let runit start nginx & php-fpm
CMD [ "/bin/docker-entrypoint.sh" ]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

ENV client_max_body_size=2M \
    clear_env=no \
    allow_url_fopen=On \
    allow_url_include=Off \
    display_errors=Off \
    file_uploads=On \
    max_execution_time=0 \
    max_input_time=-1 \
    max_input_vars=1000 \
    memory_limit=128M \
    post_max_size=50M \
    upload_max_filesize=100M \
    zlib.output_compression=On
