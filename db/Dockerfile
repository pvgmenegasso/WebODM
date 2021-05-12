FROM postgres:9.5
MAINTAINER Piero Toffanin <pt@masseranolabs.com>

ENV POSTGIS_MAJOR 2.3
ENV POSTGRES_PASSWORD postgres
ENV HTTP_PROXY=http://proxy.cnptia.embrapa.br:3128
ENV HTTPS_PROXY=https://proxy.cnptia.embrapa.br:3128

# Setup Proxy
RUN rm -rf /etc/apt/apt.conf.d
RUN mkdir /etc/apt/apt.conf.d
RUN echo $'Acquire::http::proxy::mirror.cnptia.embrapa.br DIRECT;\n\
Acquire::http::proxy "http://proxy.cnptia.embrapa.br:3128/";\n\  
Acquire::ftp::proxy "ftp://proxy.cnptia.embrapa.br:3128/";\n\
Acquire::https::proxy "http://proxy.cnptia.embrapa.br:3128/";' > /etc/apt/apt.conf.d/05-cnptia
RUN cat /etc/apt/apt.conf.d/05-cnptia


RUN . /etc/os-release \
      && echo "deb http://deb.debian.org/debian "$VERSION_CODENAME"-backports main" >> /etc/apt/sources.list \
	  && apt-get update \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
           postgis \
      && rm -rf /var/lib/apt/lists/*

EXPOSE 5432
COPY init.sql /docker-entrypoint-initdb.d/init-db.sql
RUN chmod 644 /docker-entrypoint-initdb.d/init-db.sql
