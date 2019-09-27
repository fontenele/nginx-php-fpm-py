FROM debian:9.6

LABEL maintainer="Guilherme Fontenele <guilherme@fontenele.net>"

RUN echo 'deb http://deb.debian.org/debian unstable main contrib non-free' > /etc/apt/sources.list \
    && DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    apt-utils unzip tree curl net-tools wget git vim nginx supervisor python3 sqlite3 \
    php7.3-fpm php7.3-pgsql php7.3-sqlite3 php7.3-zip php7.3-curl \
    php7.3-gd php7.3-bz2 php7.3-json php7.3-mbstring php7.3-xml php-ssh2 \
    php-redis npm \
    && mkdir /var/log/supervisord/ \
    && apt-get autoremove -y && apt-get clean

RUN openssl req -batch -nodes -newkey rsa:2048 -keyout /etc/ssl/private/server.key -out /tmp/server.csr -subj "/C=BR/ST=DF/L=Brasilia/O=Dev/OU=FS/CN=localhost" \
    && openssl x509 -req -days 365 -in /tmp/server.csr -signkey /etc/ssl/private/server.key -out /etc/ssl/certs/server.crt \
    && rm /tmp/server.csr

RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.3/fpm/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.3/fpm/php.ini \
    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.3/fpm/php.ini \
    && sed -i 's/worker_connections 768/worker_connections 4096/g' /etc/nginx/nginx.conf \
    && sed -i 's|access_log /var/log/nginx/access.log|access_log /dev/stdout|g' /etc/nginx/nginx.conf \
    && sed -i 's|error_log /var/log/nginx/error.log|error_log /dev/stderr|g' /etc/nginx/nginx.conf

RUN service php7.3-fpm start \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require hirak/prestissimo \
    && npm i -g yarn

COPY supervisord.conf /etc/supervisord.conf
COPY nginx.conf /etc/nginx/sites-enable/default

WORKDIR /var/www/html

ENTRYPOINT ["supervisor"]

EXPOSE 80 443
