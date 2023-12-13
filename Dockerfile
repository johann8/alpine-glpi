ARG ARCH=

ARG BASE_IMAGE=alpine:3.19

FROM ${ARCH}${BASE_IMAGE}

LABEL Maintainer="JH <jh@localhost>" \
      Description="Docker container with GLPI based on Alpine Linux."

ARG BUILD_DATE
ARG NAME
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name=$NAME \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/johann8/" \
      org.label-schema.version=$VERSION


# set variables
ENV GLPI_VERSION 10.0.11

ENV GLPI_LANG en_US

ENV PHP_VERSION 81

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
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-pecl-apcu \
        php${PHP_VERSION}-pecl-memcached \
        php${PHP_VERSION}-mysqli \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-sodium \
        php${PHP_VERSION}-bz2 \
        php${PHP_VERSION}-exif \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-json \
        php${PHP_VERSION}-openssl \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-zlib \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-fileinfo \
        php${PHP_VERSION}-phar \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-xmlreader \
        php${PHP_VERSION}-xmlwriter \
        php${PHP_VERSION}-ctype \
        php${PHP_VERSION}-session \
        php${PHP_VERSION}-iconv \
        php${PHP_VERSION}-tokenizer \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-simplexml \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-gettext \
        nginx \
        runit \
        curl \
        tzdata \
        #mariadb‑client \
        # php${PHP_VERSION}-pdo \
        # php${PHP_VERSION}-pdo_pgsql \
        # php${PHP_VERSION}-pdo_mysql \
        # php${PHP_VERSION}-pdo_sqlite \
        # php${PHP_VERSION}-bz2 \
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
     && chown -R nginx.nginx /var/lib/nginx
     #&& chown -R nginx.nginx /var/lib/php81     ### Since alpine 3.18 - Folder "/var/lib/php81" does not exist anymore
     #&& chown -R nobody.nobody /var/log/nginx

# Add configuration files
#COPY --chown=nobody rootfs/ /
COPY rootfs/ /
COPY scripts/backup.sh /bin/backup.sh

# Set php option
RUN echo "session.cookie_httponly = On" >> /etc/php81/conf.d/custom.ini

# create crond folder
RUN mkdir -p /etc/periodic/2min \
 && mkdir -p /etc/periodic/5min \
 && mkdir -p /etc/periodic/30min

# Set timezone
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime

# Edit php-fpm.conf
RUN sed -i 's+;pid = run/php-fpm81.pid+pid = run/php-fpm81.pid+' /etc/php81/php-fpm.conf

# Install GLPI
ADD https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz /tmp/

RUN tar -zxf /tmp/glpi-${GLPI_VERSION}.tgz -C /tmp/ \
 && mv /tmp/glpi /var/www/glpi \
 && chown -R nginx:nginx /var/www/glpi/ \
 && rm -rf /tmp/glpi-${GLPI_VERSION}.tgz


VOLUME [ "/var/www/glpi/files", "/var/www/glpi/plugins", "/var/www/glpi/config" ]


## Switch to use a non-root user from here on
#USER nobody

# Add application
WORKDIR /var/www/glpi

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
