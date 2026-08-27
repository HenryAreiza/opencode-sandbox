FROM ubuntu:24.04

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Install curl, ca-certificates, and download the official opencode binary
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -fsSL https://opencode.ai/install | bash && \
    (mv /root/.opencode/bin/opencode /usr/local/bin/opencode 2>/dev/null || true) && \
    rm -rf /var/lib/apt/lists/*

# Copy and install custom project packages
COPY packages.txt /tmp/packages.txt
RUN apt-get update && \
    grep -vE '^\s*(#|$)' /tmp/packages.txt | xargs apt-get install -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* /tmp/packages.txt

# Build arguments for host UID/GID mapping
ARG USER_ID=1000
ARG GROUP_ID=1000
ENV USER_NAME=opencode
ENV HOME=/home/${USER_NAME}

# Create or rename 'opencode' user with defined UID/GID
RUN EXISTING_USER=$(getent passwd ${USER_ID} | cut -d: -f1) && \
    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "${USER_NAME}" ]; then \
        userdel -f "$EXISTING_USER" 2>/dev/null || true; \
    fi && \
    EXISTING_GROUP=$(getent group ${GROUP_ID} | cut -d: -f1) && \
    if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "${USER_NAME}" ]; then \
        groupdel "$EXISTING_GROUP" 2>/dev/null || true; \
    fi && \
    (getent group ${GROUP_ID} || groupadd -g ${GROUP_ID} ${USER_NAME}) && \
    (getent passwd ${USER_ID} || useradd -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash ${USER_NAME}) && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 0440 /etc/sudoers.d/${USER_NAME}

USER ${USER_NAME}
WORKDIR /workspace

ENTRYPOINT ["opencode"]
CMD []
