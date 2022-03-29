FROM alpine:3.15.2
RUN apk --no-cache update && apk --no-cache upgrade && apk add --no-cache bash execline bind && cp /etc/bind/named.conf.authoritative /etc/bind/named.conf
COPY docker-entrypoint.sh /usr/local/bin
EXPOSE 53/tcp
EXPOSE 53/udp
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["named", "-g", "-c", "/etc/bind/named.conf", "-u", "named"]
