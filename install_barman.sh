#!/bin/bash

set -exo pipefail
shopt -s nullglob

# Install barman
# Create a 'barman' user that it will run as.
# Create a .ssh directory for the 'barman' user.  SSH keys will be used to rsync
#     basebackups from the database servers.
# Install the barman cron job that ensures that pg_receivexlog is running for
#     all of the database servers set to stream its WAL logs.
wget -O - https://bootstrap.pypa.io/get-pip.py | python3 -
pip install requests==2.23.0

if [[ "${SOURCE_INSTALL}" == "1" ]]; then
    apt update
    apt install -y git pip python-is-python3
    barman_path="/opt/barman"
    pip install git+${BARMAN_GIT_REPO}
    useradd --system --shell /bin/bash barman
    install -d -m 0700 -o barman -g barman ~barman/.ssh
else
    pip install barman==${BARMAN_VERSION}
    useradd --system --shell /bin/bash barman
    install -d -m 0700 -o barman -g barman ~barman/.ssh
fi

gosu barman bash -c 'echo -e "Host *\n\tCheckHostIP no" > ~/.ssh/config'
