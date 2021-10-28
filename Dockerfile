FROM debian:latest

ARG MODULE=ngx_http_proxy_connect_module
ARG VERSION=1.19.3
ARG PREFIX=/etc/nginx

# Required packages
RUN set -eux; \
    apt-get update; \
    apt-get install --no-install-recommends --no-install-suggests -y \
	ca-certificates git wget \
	build-essential libssl-dev libpcre3-dev zlib1g-dev; \
    rm -rf /var/lib/apt/lists/*

# Build nginx
WORKDIR /usr/src/
RUN set -eux; \
    git clone https://github.com/chobits/$MODULE; \
    wget http://nginx.org/download/nginx-$VERSION.tar.gz; \
    tar xzf nginx-$VERSION.tar.gz; \
    cd nginx-$VERSION; \
    patch -p1 < ../$MODULE/patch/proxy_connect_rewrite_1018.patch; \
    ./configure \
	--prefix=$PREFIX --sbin-path=/usr/bin \
	--with-threads \
	--with-http_ssl_module --add-module=../$MODULE; \
    make; \
    make install; \
    make clean; \
    cd -; \
    rm -rf ./*
    
# Logging
RUN set -eux; \
    ln -sf /dev/stdout $PREFIX/logs/access.log; \
    ln -sf /dev/stderr $PREFIX/logs/error.log

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
