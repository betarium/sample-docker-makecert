FROM alpine
RUN apk add bash openssl

WORKDIR /var/docker-makecert
COPY docker-makecert.sh makecert
RUN chmod +x makecert

WORKDIR /var/docker-makecert/cert
ENV PATH=/var/docker-makecert:$PATH

ENTRYPOINT ["makecert"]

