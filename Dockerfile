FROM amazonlinux:2
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
      python37 \
      python37-devel \
      python37-virtualenv \
      python37-setuptools \
      rsync \
      tar \
      wget \
      which \
      zip
CMD mkdir /var/app