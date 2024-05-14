# syntax=docker/dockerfile:1

# Stage 1: Build dependencies
FROM composer:lts AS deps
WORKDIR /app
COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/root/.composer/cache \
    composer install --no-dev --no-interaction --prefer-dist

# Stage 2: Build and test
FROM php:7.4.33-apache AS test
WORKDIR /var/www/html
COPY --from=deps /app/vendor ./vendor
COPY ./src ./ 
RUN docker-php-ext-install pdo pdo_mysql

# Stage 3: Final build
FROM php:7.4.33-apache
WORKDIR /var/www/html
COPY --from=deps /app/vendor ./vendor
COPY ./src ./
RUN docker-php-ext-install pdo pdo_mysql

# Use the default production configuration for PHP runtime arguments
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Switch to a non-privileged user (defined in the base image) that the app will run under
USER www-data
