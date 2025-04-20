ARG BARMAN_VERSION
ARG SOURCE_INSTALL "0"

FROM debian:bullseye

ARG BARMAN_VERSION
ARG SOURCE_INSTALL "0"

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget gnupg2 gosu tini tmux && rm -rf /var/lib/apt/lists/* && \
    gosu nobody true

# Install postgres 9.4, 9.5, 9.6 clients.  This is so that barman can use the
# appropriate version when using pg_basebackup.
# Install some other requirements as well.
#   cron: For scheduling base backups
#   gcc: For building psycopg2
#   libpq-dev: Needed to build/run psycopg2
#   libpython-dev: For building psycopg2
#   openssh-client: Needed to rsync basebackups from the database servers
#   python: Needed to run barman
#   rsync: Needed to rsync basebackups from the database servers
#   gettext-base: envsubst
RUN bash -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' && \
    (wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -) && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        gcc \
        libpq-dev \
        libpython3-dev \
        openssh-client \
        postgresql-client-12 \
        postgresql-client-13 \
        postgresql-client-14 \
        postgresql-client-15 \
        postgresql-client-16 \
        postgresql-client-17 \
        python3 \
        python3-distutils \
        rsync \
        gettext-base \
        procps && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /etc/crontab /etc/cron.*/* && \
    sed -i 's/\(.*pam_loginuid.so\)/#\1/' /etc/pam.d/cron && \
    mkdir -p /etc/barman/barman.d

# Set up some defaults for file/directory locations used in entrypoint.sh.
ENV \
    BARMAN_VERSION=${BARMAN_VERSION} \
    SOURCE_INSTALL=${SOURCE_INSTALL} \
    BARMAN_CRON_SRC=/private/cron.d \
    BARMAN_DATA_DIR=/var/lib/barman \
    BARMAN_LOG_DIR=/var/log/barman \
    BARMAN_SSH_KEY_DIR=/private/ssh \
    BARMAN_CRON_SCHEDULE="* * * * *" \
    BARMAN_BACKUP_SCHEDULE="0 4 * * *" \
    BARMAN_LOG_LEVEL=INFO \
    DB_HOST=pg \
    DB_PORT=5432 \
    DB_SUPERUSER=postgres \
    DB_SUPERUSER_PASSWORD=postgres \
    DB_SUPERUSER_DATABASE=postgres \
    DB_REPLICATION_USER=standby \
    DB_REPLICATION_PASSWORD=standby \
    DB_SLOT_NAME=barman \
    DB_BACKUP_METHOD=postgres \
    BARMAN_EXPORTER_SCHEDULE="*/5 * * * *" \
    BARMAN_EXPORTER_LISTEN_ADDRESS="0.0.0.0" \
    BARMAN_EXPORTER_LISTEN_PORT=9780 \
    BARMAN_EXPORTER_CACHE_TIME=3600 \
    BARMAN_GIT_REPO=https://github.com/EnterpriseDB/barman.git

VOLUME ${BARMAN_DATA_DIR}

COPY install_barman.sh /tmp/
RUN chmod +x /tmp/install_barman.sh && /tmp/install_barman.sh && rm /tmp/install_barman.sh
COPY barman.conf.template /etc/barman.conf.template
COPY pg.conf.template /etc/barman/barman.d/pg.conf.template

ENV PYTHONPATH: "${PYTHONPATH}:/opt/barman"

# Install barman exporter
RUN pip install barman-exporter && mkdir /node_exporter
VOLUME /node_exporter

# Install the entrypoint script.  It will set up ssh-related things and then run
# the CMD which, by default, starts cron.  The 'barman -q cron' job will get
# pg_receivexlog running.  Cron may also have jobs installed to run
# 'barman backup' periodically.
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["cron", "-L", "4", "-f"]
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
WORKDIR ${BARMAN_DATA_DIR}
