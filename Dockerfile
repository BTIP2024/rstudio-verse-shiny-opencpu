# Use builds from launchpad
FROM btip2024/rstudio-verse-shiny

ARG BRANCH=master
ENV DEBIAN_FRONTEND noninteractive

# Install and 'hold' opencpu-server so that the docker image can be tagged
#RUN \
#  apt-get update && \
#  apt-get -y dist-upgrade && \
#  apt-get install -y software-properties-common && \
#  add-apt-repository -y ppa:opencpu/opencpu-2.2 && \
#  apt-get update && \
#  apt-get install -y opencpu-server && \
#  apt-mark hold opencpu-server

RUN \ 
  apt-get update && \
  apt-get upgrade

RUN \
  apt-get install -y \ 
    wget \
    make \
    devscripts \
    apache2-dev \
    apache2 \
    libapreq2-dev \
    libapparmor-dev \
    libcurl4-openssl-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libcairo2-dev \
    libfontconfig-dev \
    xvfb xauth \
    xfonts-base \
    curl \
    libssl-dev \
    libxml2-dev \
    libicu-dev \
    pkg-config \
    libssh2-1-dev \
    locales \
    apt-utils \
    cmake

# Different from debian
RUN \ 
  apt-get install -y language-pack-en-base

RUN \ 
  useradd -ms /bin/bash builder

USER builder

RUN \ 
  cd ~ && \
  wget --quiet https://github.com/opencpu/opencpu-server/archive/${BRANCH}.tar.gz && \
  tar xzf ${BRANCH}.tar.gz && rm ${BRANCH}.tar.gz && \
  cd opencpu-server-* && \
  dpkg-buildpackage -us -uc -d

USER root
#WORKDIR /root/
#COPY /home/builder/opencpu*deb ./

RUN \ 
  apt-get install -y \
   software-properties-common \
   gdebi-core \
   git \
   sudo \
   cron

RUN \ 
  add-apt-repository -y ppa:opencpu/opencpu-2.2

#RUN \ 
#  cd /home/builder/

RUN \ 
  gdebi --non-interactive /home/builder/opencpu*.deb
#  gdebi --non-interactive opencpu-lib_*.deb && \
#  gdebi --non-interactive opencpu-server_*.deb

# create init scripts
RUN \
  mkdir -p /etc/services.d/opencpu-server && \
  echo "#!/usr/bin/with-contenv bash" >> /etc/services.d/opencpu-server/run && \
  echo "## load /etc/environment vars first:" >> /etc/services.d/opencpu-server/run && \
  echo "exec apachectl -DFOREGROUND" >> /etc/services.d/opencpu-server/run && \
  chmod +x /etc/services.d/opencpu-server/run  

RUN \ 
  mkdir -p /etc/services.d/cron && \
  echo "#!/usr/bin/with-contenv bash" >> /etc/services.d/cron/run && \ 
  echo "## load /etc/environment vars first:" >> /etc/services.d/cron/run && \
  echo "exec service cron start" >> /etc/services.d/cron/run && \
  chmod +x /etc/services.d/cron/run

# Prints apache logs to stdout
RUN \
  ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
  ln -sf /proc/self/fd/1 /var/log/apache2/error.log && \
  ln -sf /proc/self/fd/1 /var/log/opencpu/apache_access.log && \
  ln -sf /proc/self/fd/1 /var/log/opencpu/apache_error.log

# Set opencpu password so that we can login
RUN \
  echo "opencpu:opencpu" | chpasswd

# Apache ports
EXPOSE 80
EXPOSE 443
EXPOSE 8004

# Start non-daemonized webserver
#CMD \init && service cron start && apachectl -DFOREGROUND
CMD ["/init"]
