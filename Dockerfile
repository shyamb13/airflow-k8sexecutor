# VERSION 1.10.3
# AUTHOR: APE
# DESCRIPTION: APE Airflow container
# BUILD: docker build --rm -t docker-airflow .


FROM samb1392/python3.6
LABEL maintainer="InfosysDNA"

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
#ape_change_start
ARG AIRFLOW_VERSION=1.10.3
#ape_change_end
ARG AIRFLOW_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_GPL_UNIDECODE yes

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
#ape_chnage in apt-get install
# Added from zlib1g-dev \ to libjpeg62-turbo-dev  And added pip==9.0.1



RUN set -ex \
    && buildDeps=' \
      freetds-dev \
        python3-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
       libblas-dev \
       liblapack-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
       python3-pip \
       python3-requests \
       mysql-client \
       mysql-server \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        zlib1g-dev \
        bzip2-doc \
        libbz2-dev \
        libssl-dev \
        libgpm2 \
        libncurses5 \
        libtinfo-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libsqlite3-dev \
        default-libmysqlclient-dev \
        g++ \
        wget \
        unzip \
        vim \
        git \
        python-dev \
	    alien \
	    libaio1 \
	    openssh-server \
	    libgnutls-openssl-dev \
	    libxml2-dev \
	    libxslt1-dev \
        libjpeg62-turbo-dev \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    #&& pip install azure-cli~=2.0.55 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,kubernetes,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'redis>=2.10.5,<3' \
    && pip install pip==9.0.1 \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base
#ape_chnage_start

RUN curl -sL https://aka.ms/InstallAzureCLIDeb |  bash

COPY ./script/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

# install Java
USER root
RUN mkdir -p /usr/share/man/man1 && \
apt-get update -y && \
apt-get install -y openjdk-8-jdk


RUN apt-get install unzip -y && \
apt-get autoremove -y


COPY script/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#ape_change_end

COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow

WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"] # set default arg for entrypoint