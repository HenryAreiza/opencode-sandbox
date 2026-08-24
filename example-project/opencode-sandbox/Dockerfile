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

# Reuse existing user (e.g. 'ubuntu' in Ubuntu 24.04) or create 'opencode'
RUN USER_NAME=$(getent passwd ${USER_ID} | cut -d: -f1) || true; \
    if [ -z "$USER_NAME" ]; then \
        USER_NAME=opencode; \
        groupadd -g ${GROUP_ID} ${USER_NAME} 2>/dev/null || true; \
        useradd -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash ${USER_NAME} 2>/dev/null || true; \
    fi; \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sandbox-user && \
    chmod 0440 /etc/sudoers.d/sandbox-user

USER ${USER_ID}:${GROUP_ID}
ENV HOME=/home/opencode
WORKDIR /workspace

ENTRYPOINT ["opencode"]
CMD []
