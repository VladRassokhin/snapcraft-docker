ARG RISK=stable
ARG UBUNTU=jammy

FROM ubuntu:$UBUNTU as builder
ARG RISK
ARG UBUNTU
RUN echo "Building snapcraft:$RISK in ubuntu:$UBUNTU"

# Grab dependencies
RUN apt-get update && apt-get -y dist-upgrade && apt-get -y install \
      curl \
      jq \
      squashfs-tools

# Download and unpack snap bases and snapcraft as a snap
COPY prepare.sh .
RUN chmod 755 prepare.sh && ./prepare.sh

# Fix Python3 installation: Make sure we use the interpreter from
# the snapcraft snap:
RUN unlink /snap/snapcraft/current/usr/bin/python3
RUN ln -s /snap/snapcraft/current/usr/bin/python3.* /snap/snapcraft/current/usr/bin/python3
RUN echo /snap/snapcraft/current/lib/python3.*/site-packages >> /snap/snapcraft/current/usr/lib/python3/dist-packages/site-packages.pth


# Multi-stage build, only need the snaps from the builder. Copy them one at a
# time so they can be cached.
FROM ubuntu:$UBUNTU
COPY --from=builder /snap/core /snap/core
COPY --from=builder /snap/core18 /snap/core18
COPY --from=builder /snap/core20 /snap/core20
COPY --from=builder /snap/core22 /snap/core22
COPY --from=builder /snap/snapcraft /snap/snapcraft
COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# Generate locale and install dependencies.
RUN apt-get update && apt-get -y dist-upgrade && apt-get -y install \
      snapd \
      sudo \
      locales \
    && locale-gen en_US.UTF-8

# Set the proper environment.
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/bin:/snap/snapcraft/current/usr/bin:$PATH"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAPCRAFT_BUILD_ENVIRONMENT=host
