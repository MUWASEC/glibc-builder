FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# update and install necessary packages
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y \
        build-essential \
        gcc \
        make \
        patch \
        xz-utils \
        gawk \
        bison \
        wget \
        gcc-multilib \
        dh-make-perl \
        apt-file && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY build.sh .
RUN chmod +x build.sh

# Set default command (optional)
CMD ["/bin/bash"]