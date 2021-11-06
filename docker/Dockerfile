FROM alpine
RUN apk add bash openssl

WORKDIR /var/docker-makecert
COPY docker-makecert.sh makecert
RUN chmod +x makecert

RUN mkdir /var/docker-makecert/cert
RUN chmod 777 /var/docker-makecert/cert
ENV PATH=/var/docker-makecert:$PATH

ENTRYPOINT ["makecert"]

