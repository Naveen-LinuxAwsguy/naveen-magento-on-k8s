FROM nginx:1.18 as nginx_builder

FROM php:8.1.0-fpm-buster

ENV APP_HOME /var/www/html/magento
ENV TMP_APP_HOME /var/tmp/magento
ENV PHP_EXT_APCU_VERSION "5.1.18"
ENV PHP_EXT_MEMCACHED_VERSION "3.1.5"
ENV PHP_CONF /usr/local/etc/php/php.ini
ENV FPM_CONF /usr/local/etc/php-fpm.d/www.conf

RUN buildDeps='curl gcc make autoconf libc-dev zlib1g-dev pkg-config' \
    && set -x \
    && apt-get update \
    && apt-get install --no-install-recommends $buildDeps --no-install-suggests -q -y gnupg2 dirmngr wget apt-transport-https lsb-release ca-certificates

## INSTALLING NGINX ###
COPY --from=nginx_builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx_builder /etc/nginx /etc/nginx
RUN mkdir -p /var/log/nginx/
RUN mkdir -p /var/cache/nginx

RUN apt-get update && apt-get install -y \
      libicu-dev \
      libpq-dev \
      libmcrypt-dev \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng-dev \
      libwebp-dev \
      libgmp-dev \
      libxml2-dev \
      libxslt1-dev \
      libmemcached-dev \
      sendmail-bin \
      sendmail \
      libonig-dev \
      libldap2-dev \
      zlib1g-dev \
      libzip-dev \
      openssl \
      git \
      zip \
      unzip \
      vim \
      nano \
      curl \
      iputils-ping \
      python-pip \
      python-setuptools \
    && pip install wheel \
    && pip install supervisor supervisor-stdout \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-webp=/usr/include/ \
    && pecl install mcrypt \
    && docker-php-ext-enable mcrypt \
    && yes "" | pecl install apcu-$PHP_EXT_APCU_VERSION && docker-php-ext-enable apcu \
    && echo "no" | pecl install memcached-$PHP_EXT_MEMCACHED_VERSION && docker-php-ext-enable memcached \
    && docker-php-ext-install \
      intl \
      mbstring \
      pdo_mysql \
      mysqli \
      gd \
      gmp \
      bcmath \
      pcntl \
      ldap \
      sysvmsg \
      exif \
      zip \
      soap \
      pcntl \
      xsl \
      sockets \
    && docker-php-ext-enable mysqli \
    && apt-get purge -y --auto-remove $buildDeps \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN adduser --disabled-password --gecos '' --uid 1000 nginx

# Install Composer
COPY --from=composer:2.1 /usr/bin/composer /usr/local/bin/composer

# Copy Magento Source Codes
COPY magento/. ${TMP_APP_HOME}/.
COPY config/auth.json ${TMP_APP_HOME}/auth.json

# Override php.ini config
RUN rm -rf /usr/local/etc/php/php.ini.production
COPY config/php.ini /usr/local/etc/php/php.ini

# Supervisor config
COPY config/supervisord.conf /etc/supervisord.conf

# Override nginx's default config
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/conf.d/default.conf

# Php-fpm config
COPY config/www.conf ${FPM_CONF}

# Setting Permission for nginx user
RUN chown -R nginx:nginx  ${TMP_APP_HOME}
RUN chmod -R 777 ${TMP_APP_HOME}/pub/* ${TMP_APP_HOME}/var/* ${TMP_APP_HOME}/generated/*


# Copy Run Scripts
COPY config/run.sh /run.sh
RUN chmod +x /run.sh

RUN mkdir -p /etc/nginx/run
RUN chown nginx:nginx /etc/nginx

EXPOSE 8080 9000

WORKDIR ${APP_HOME}

CMD ["/run.sh"]