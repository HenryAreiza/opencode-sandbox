FROM ghcr.io/anomalyco/opencode:latest

USER root

# Copy package list
COPY packages.txt /tmp/packages.txt

# Install packages via apk (ignoring comments/empty lines) and clean cache
RUN apk update && \
    grep -vE '^\s*(#|$)' /tmp/packages.txt | xargs apk add --no-cache && \
    rm -rf /var/cache/apk/* /tmp/packages.txt

# Ensure 'python' alias points to python3
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Build arguments for host UID/GID mapping
ARG USER_ID=1000
ARG GROUP_ID=1000

# Reuse existing user if UID exists, or create a new user and grant passwordless sudo
RUN USER_NAME=$(getent passwd ${USER_ID} | cut -d: -f1) || true; \
    if [ -z "$USER_NAME" ]; then \
        USER_NAME=opencode; \
        (getent group ${GROUP_ID} || addgroup -g ${GROUP_ID} ${USER_NAME}) 2>/dev/null || true; \
        adduser -u ${USER_ID} -G $(getent group ${GROUP_ID} | cut -d: -f1) -s /bin/bash -D ${USER_NAME} 2>/dev/null || true; \
    fi; \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sandbox-user && \
    chmod 0440 /etc/sudoers.d/sandbox-user

USER ${USER_ID}:${GROUP_ID}
ENV HOME=/home/opencode
WORKDIR /workspace

ENTRYPOINT ["opencode"]
CMD []
