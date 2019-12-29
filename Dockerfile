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
      python3 \
      python3-devel \
      python3-virtualenv \
      python3-setuptools \
      rsync \
      tar \
      wget \
      which \
      zip
CMD mkdir /var/app