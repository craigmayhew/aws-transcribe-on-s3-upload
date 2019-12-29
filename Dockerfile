FROM amazonlinux:2018.03
RUN yum update -y
RUN yum install -y \
      Cython \
      findutils \
      gcc \
      gcc-c++ \
      gzip \
      findutils \
      libxml2 \
      libxslt \
      make \
      man-pages \
      man \
      python36 \
      python36-devel \
      python36-virtualenv \
      python34-setuptools \
      rsync \
      tar \
      wget \
      which \
      zip
CMD mkdir /var/app