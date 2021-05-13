FROM ubuntu:20.04
MAINTAINER Piero Toffanin <pt@masseranolabs.com>
MAINTAINER Pedro Vinícius <pedro.menegasso@colaborador.embrapa.br>

ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH $PYTHONPATH:/webodm
ENV PROJ_LIB=/usr/share/proj
ENV http_proxy=http://proxy.cnptia.embrapa.br:3128
ENV https_proxy=https://proxy.cnptia.embrapa.br:3128

# Setup Proxy
RUN rm -rf /etc/apt/apt.conf.d
RUN mkdir /etc/apt/apt.conf.d
RUN echo $'Acquire::http::proxy::mirror.cnptia.embrapa.br DIRECT;\n\
Acquire::http::proxy "http://proxy.cnptia.embrapa.br:3128/";\n\  
Acquire::ftp::proxy "ftp://proxy.cnptia.embrapa.br:3128/";\n\
Acquire::https::proxy "https://proxy.cnptia.embrapa.br:3128/";' > /etc/apt/apt.conf.d/05-cnptia
RUN cat /etc/apt/apt.conf.d/05-cnptia


# Prepare directory
RUN mkdir /webodm
WORKDIR /webodm

RUN apt-get -qq update && apt-get install -y software-properties-common tzdata
# Add GPG key for postgis manually due to proxy issues
RUN echo $'-----BEGIN PGP PUBLIC KEY BLOCK-----\n\
Comment: Hostname: \n\
Version: Hockeypuck ~unreleased\n\
\n\
xo0ESgc8TwEEANnh7UAVSnJoE8fyLMss5VUuG+1Bw5W2XWEyxuOCfMMAnJq4FY7Y\n\
OjaFwX37KdPTy5/+NVqegazUbB3WV8d21aRhN977HXYztt/1Ft73m30FLbZC3vRw\n\
aMg5oaWQ/XAy9ONY8QND/ahhSNf3d8wyrfAlG2RLaUeASDXqMBOU2fKVABEBAAHN\n\
GkxhdW5jaHBhZCB1YnVudHVnaXMtc3RhYmxlwrYEEwECACAFAkoHPE8CGwMGCwkI\n\
BwMCBBUCCAMEFgIDAQIeAQIXgAAKCRAInr4IMU3xYG3iA/0dnVOYqpLayEgzmlJ6\n\
mwJnVKcL+tGRfNsKQTHe77skFBcO/YyLez29HJJJS0xGtkZ+bUEQ3mdKnV/jGK4y\n\
geSouItfz3fM3/PvVbZMbARUTzOdIR/Hv8GUyVhY3dPR8NEyw0Op41kCOuxZBVU9\n\
85IQHDDQe6Fw1q6IFjOES0NMjQ==\n\
=ab3/\n\
-----END PGP PUBLIC KEY BLOCK-----\n\' >> key.txt
RUN gpg --keyserver-options "http-proxy=http://proxy.cnptia.embrapa.br:3128/" --import key.txt
RUN apt-get update

# Install Node.js
RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends wget curl
RUN wget --no-check-certificate https://deb.nodesource.com/setup_12.x -O /tmp/node.sh && bash /tmp/node.sh
RUN apt-get -qq update && apt-get -qq install -y nodejs

# Install Python3, GDAL, nginx, letsencrypt, psql
RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends python3 python3-pip python3-setuptools python3-wheel git g++ python3-dev python2.7-dev libpq-dev binutils libproj-dev gdal-bin python3-gdal nginx certbot grass-core gettext-base cron postgresql-client-12 gettext
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 && update-alternatives --install /usr/bin/python python /usr/bin/python3.8 2
RUN ln -s /usr/bin/pip3 /usr/bin/pip && pip install -U pip

# Install pip reqs
ADD requirements.txt /webodm/
RUN pip install -r requirements.txt

ADD . /webodm/

# Setup cron
RUN ln -s /webodm/nginx/crontab /var/spool/cron/crontabs/root && chmod 0644 /webodm/nginx/crontab && service cron start && chmod +x /webodm/nginx/letsencrypt-autogen.sh

#RUN git submodule update --init
RUN apt-get update -y 
RUN apt-get upgrade -y
RUN apt-get install -y build-essential

WORKDIR /webodm/nodeodm/external/NodeODM
RUN npm install --quiet

WORKDIR /webodm
RUN npm install --quiet -g webpack@4.16.5 && npm install --quiet -g webpack-cli@4.2.0 && npm install --quiet && webpack --mode production
RUN echo "UTC" > /etc/timezone
RUN python manage.py collectstatic --noinput
RUN bash app/scripts/plugin_cleanup.sh && echo "from app.plugins import build_plugins;build_plugins()" | python manage.py shell
RUN bash translate.sh build safe

# Cleanup
#RUN apt-get remove -y g++ python3-dev libpq-dev && apt-get autoremove -y
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN rm /webodm/webodm/secret_key.py

VOLUME /webodm/app/media
