FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install -y wget

# add UCSB repository
RUN wget -O - http://biodev.ece.ucsb.edu/debian/cbi_repository_key.asc | apt-key add -
RUN echo "deb http://biodev.ece.ucsb.edu/debian/archive unstable/" > /etc/apt/sources.list.d/bisque.list
RUN apt-get update

RUN locale-gen fi_FI.UTF-8

RUN apt-get install -y imgcnv libopenjpeg5 libopenslide-dev

RUN apt-get install -y python-dev python-setuptools python-pip
RUN pip install virtualenv
RUN apt-get install -y libxml2-dev
RUN apt-get install -y libxslt-dev
RUN apt-get install -y python-libxml2
RUN apt-get install -y libldap2-dev
RUN apt-get install -y libsasl2-dev
RUN apt-get install -y yasm
RUN apt-get install -y libxvidcore-dev
RUN apt-get install -y libopenjpeg-dev
RUN apt-get install -y libschroedinger-dev
RUN apt-get install -y libtheora-dev
RUN apt-get install -y libbz2-dev
RUN apt-get install -y python-psycopg2
RUN apt-get install -y libfftw3-dev
RUN apt-get install -y libvpx-dev
RUN apt-get install -y libx264-dev
RUN apt-get install -y libsvm-tools
RUN apt-get install -y libz-dev

# iRODS Python 
RUN wget --no-check-certificate https://irodspython.googlecode.com/git/Downloads/PyRods-3.3.5.tar.gz
RUN tar xf PyRods-3.3.5.tar.gz
RUN apt-get install -y gcc make g++
RUN cd PyRods-3.3.5; export CFLAGS=-fPIC; ./scripts/configure; make clients; python setup.py build; sudo python setup.py install

# HTCondor
RUN echo "deb http://research.cs.wisc.edu/htcondor/debian/stable/ wheezy contrib" >> /etc/apt/sources.list.d/htcondor.list
RUN apt-get update
#RUN apt-get -f -y install
RUN apt-get install -y --force-yes condor

RUN wget http://hydra.nixos.org/build/1524644/download/1/patchelf_0.6-1_amd64.deb
RUN dpkg -i patchelf_0.6-1_amd64.deb

RUN mkdir /bisque_install
WORKDIR /bisque_install

RUN wget http://biodev.ece.ucsb.edu/binaries/depot/bisque-bootstrap.py
RUN python bisque-bootstrap.py
RUN . bqenv/bin/activate; pip install -r requirements.txt
RUN . bqenv/bin/activate; paver setup server

ADD config/setup-server-answers0.txt /bisque_install/
RUN . bqenv/bin/activate; bq-admin setup -r setup-server-answers0.txt server

# edit site.cfg to make uwsgi default 
RUN sed -i.backup1 -e '/backend.*=.*uwsgi/s/#//' -e '/backend.*=.*paster/d' -e '/\.uwsgi/s/#//' config/site.cfg

ADD config/setup-server-answers.txt /bisque_install/
RUN . bqenv/bin/activate; bq-admin setup -r setup-server-answers.txt server

VOLUME /var/socket/
RUN sed -i.backup2 -e '/uwsgi.socket/s#/tmp#/var/socket#' config/site.cfg

#CMD sleep 10m

RUN adduser --disabled-login bisque;
RUN chown bisque:bisque /bisque_install
RUN chown bisque:bisque /var/socket

USER bisque

CMD . bqenv/bin/activate; uwsgi --ini config/h1_uwsgi.cfg
