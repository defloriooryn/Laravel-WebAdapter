FROM composer:2.4.3 as builder

COPY . /app

# Change to production mode.
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress
RUN php artisan cache:clear
RUN php artisan route:cache
RUN php artisan view:cache
RUN php artisan optimize


FROM alpine:3.16

WORKDIR /app

# Install PHP
RUN apk add --no-cache php8 \
    php8-common \
    php8-ctype \
    php8-bcmath \
    php8-pdo \
    php8-zip \
    php8-cli \
    php8-openssl \
    php8-mbstring \
    php8-tokenizer \
    php8-fileinfo \
    php8-json \
    php8-xml \
    php8-xmlwriter \
    php8-xmlreader \
    php8-simplexml \
    php8-dom \
    php8-tokenizer \
    php8-apache2 \ 
    php8-session

# Install Apache
RUN apk add --no-cache apache2

# Links Stream.
RUN rm -rf /var/log/apache2 && mkdir -m 777 /var/log/apache2
RUN touch /var/log/apache2/error.log && chmod 777 /var/log/apache2/error.log
RUN touch /var/log/apache2/access.log && chmod 777 /var/log/apache2/access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log
RUN ln -sf /dev/stdout /var/log/apache2/access.log

# Apache config.
COPY .config/httpd.conf /etc/apache2/httpd.conf
COPY .config/mpm.conf /etc/apache2/conf.d/mpm.conf
RUN chown -R apache:apache /var/log/apache2
RUN addgroup root apache

# Copy source code.
COPY --from=builder /app /app
COPY .config/index.php .

# Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.5.0 /lambda-adapter /opt/extensions/lambda-adapter
EXPOSE 8080
##ENV PORT=8080

CMD httpd -D FOREGROUND 
