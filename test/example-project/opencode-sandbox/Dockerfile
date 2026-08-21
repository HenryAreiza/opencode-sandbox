# Custom Docker Sandbox for Example Project
FROM ghcr.io/anomalyco/opencode:latest

USER root

# Copy package list and Python requirements
COPY packages.txt /tmp/packages.txt
COPY requirements.txt /tmp/requirements.txt

# Install system packages via apk (ignoring comments/empty lines) and clean cache
RUN apk update && \
    grep -vE '^\s*(#|$)' /tmp/packages.txt | xargs apk add --no-cache && \
    rm -rf /var/cache/apk/* /tmp/packages.txt

# Install custom Python requirements
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt

# Ensure 'python' alias points to python3
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Build arguments for host UID/GID mapping
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USER_NAME=opencode

# Configure non-root user matching host UID/GID with sudo rights
RUN (getent group ${GROUP_ID} || addgroup -g ${GROUP_ID} ${USER_NAME}) 2>/dev/null || true && \
    (id -u ${USER_ID} >/dev/null 2>&1 || adduser -u ${USER_ID} -G $(getent group ${GROUP_ID} | cut -d: -f1) -s /bin/bash -D ${USER_NAME}) 2>/dev/null || true && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 0440 /etc/sudoers.d/${USER_NAME}

USER ${USER_NAME}
ENV HOME=/home/${USER_NAME}
WORKDIR /workspace

ENTRYPOINT ["opencode"]
CMD []
