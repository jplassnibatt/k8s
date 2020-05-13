FROM rundeckpro/enterprise:SNAPSHOT as rundeck

USER root

RUN echo "deb http://archive.ubuntu.com/ubuntu xenial-updates main restricted universe multiverse /" | sudo tee -a /etc/apt/sources.list

RUN apt-get -y update && \
    apt-get -y install \
    software-properties-common  \
    apt-transport-https \
    iputils-ping \
    netcat-traditional \
    sysstat \
    vim \
    build-essential \
    openssh-server \
    unzip \
    zip \
    jq \
    nano \
    sysstat

RUN apt-get install -y libffi-dev

RUN apt-get install libssl-dev openssl gcc make -y && \
    cd /opt && \
    wget https://www.python.org/ftp/python/3.8.2/Python-3.8.2.tgz && \
    tar xzvf Python-3.8.2.tgz && \
    cd Python-3.8.2 && \
    ./configure --with-ensurepip=install && \
    make && \
    make install

ENV PATH="/opt/Python-3.8.2:$PATH"

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python get-pip.py

RUN apt-get install -y gcc python-dev libkrb5-dev krb5-user
## Install python winrm
RUN python -m pip install --upgrade pip && \
    python -m pip install setuptools --force --upgrade && \
    python -m pip install requests urllib3 pywinrm && \
    python -m pip install pywinrm[credssp] && \
    python -m pip install pywinrm[kerberos] && \
    python -m pip install pexpect

RUN cpan JSON::MaybeXS
RUN cpan YAML

# install ansible
RUN apt-get -y install sshpass && \
    apt-get -y install python3-pip && \
    apt-get -y install python-pip && \
    pip3 install --upgrade pip

RUN pip3 install ansible
RUN pip install docker-py

# install docker on container
RUN apt-get -y install docker.io

#set rundeck password
RUN echo 'rundeck:rundeck' | chpasswd
#RUN /etc/init.d/ssh status

USER rundeck
ENV RDECK_BASE=/home/rundeck \
    ANSIBLE_CONFIG=/home/rundeck/ansible/ansible.cfg \
    ANSIBLE_HOST_KEY_CHECKING=False\
    USER=rundeck

ENV PATH="/opt/Python-3.8.2:$PATH"

#RUN mkdir data demo-projects
RUN mkdir data
COPY --chown=rundeck:root remco /etc/remco
COPY --chown=rundeck:root ./ansible ./ansible
COPY --chown=rundeck:root ./plugins ./libext
COPY --chown=rundeck:root ./data/linux_id_rsa /home/rundeck/ansible/id_rsa
RUN chmod 600 /home/rundeck/ansible/id_rsa
#COPY --chown=root:root config /etc/krb5.conf
