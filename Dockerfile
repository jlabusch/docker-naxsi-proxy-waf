# Forked from Thibaut Lapierre's https://github.com/epheo/docker-naxsi-proxy-waf

FROM debian:jessie

MAINTAINER Jacques Labuschagne <jlabusch@acm.org>

ENV NGINX_VERSION 1.8.1
ENV NAXSI_VERSION 0.54
ENV PROXY_REDIRECT_IP haproxy

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl build-essential bzip2 libpcre3-dev libssl-dev daemon libgeoip-dev && \
    cd /usr/src && \
    curl -sL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -zxv && \
    curl -sL https://github.com/nbs-system/naxsi/archive/0.54.tar.gz | tar -zxv && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
         --conf-path=/etc/nginx/nginx.conf \
         --add-module=../naxsi-${NAXSI_VERSION}/naxsi_src/ \
         --error-log-path=/var/log/nginx/error.log \
         --http-client-body-temp-path=/var/lib/nginx/body \
         --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
         --http-log-path=/var/log/nginx/access.log \
         --http-proxy-temp-path=/var/lib/nginx/proxy \
         --lock-path=/var/lock/nginx.lock \
         --pid-path=/var/run/nginx.pid \
         --with-http_ssl_module \
         --without-mail_pop3_module \
         --without-mail_smtp_module \
         --without-mail_imap_module \
         --without-http_uwsgi_module \
         --without-http_scgi_module \
         --with-http_gzip_static_module \
         --with-ipv6 --prefix=/usr && \
    make && make install

ADD nginx/nginx.conf /etc/nginx/nginx.conf
ADD nginx/naxsi.rules /etc/nginx/naxsi.rules
ADD nginx/naxsi_core.rules /etc/nginx/naxsi_core.rules
ADD nginx/localhost.conf /etc/nginx/localhost.conf

RUN touch /etc/nginx/naxsi_all.rules && \
    mkdir /var/lib/nginx && \
    sed -i s/'<proxy_redirect_ip>'/${PROXY_REDIRECT_IP}/g /etc/nginx/localhost.conf && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/nginx/localhost.access.log && \
    ln -sf /dev/stderr /var/log/nginx/localhost.error.log && \
    ln -sf /dev/stdout /var/log/nginx/stats.access.log && \
    ln -sf /dev/stderr /var/log/nginx/stats.error.log && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 80 443 8081

CMD ["/usr/sbin/nginx"]

