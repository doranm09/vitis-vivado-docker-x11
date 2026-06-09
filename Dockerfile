# Vitis/Vivado 2022.2 runtime base on Ubuntu 22.04 with Linux X11 GUI support.
#
# This image intentionally DOES NOT download or embed the AMD/Xilinx installer.
# Place the installer in ./installers and run the one-shot xilinx-install service.

FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=xilinx
ARG USER_UID=1000
ARG USER_GID=1000

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    locales \
    sudo \
    bash \
    curl \
    wget \
    git \
    make \
    cmake \
    build-essential \
    file \
    tar \
    gzip \
    bzip2 \
    unzip \
    xz-utils \
    python3 \
    python3-pip \
    python3-venv \
    usbutils \
    pciutils \
    udev \
    procps \
    net-tools \
    iproute2 \
    iputils-ping \
    lsof \
    less \
    nano \
    vim \
    xauth \
    x11-apps \
    dbus-x11 \
    xterm \
    libtinfo5 \
    libncurses5 \
    libncursesw5 \
    libstdc++6 \
    libglib2.0-0 \
    libgtk2.0-0 \
    libgtk-3-0 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxft2 \
    libsm6 \
    libfontconfig1 \
    libnss3 \
    libasound2 \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libxinerama1 \
    libxcursor1 \
    libxcomposite1 \
    libxcb1 \
    libxcb-xinerama0 \
    libxcb-render0 \
    libxcb-shape0 \
    libgl1 \
    libglu1-mesa \
    mesa-utils \
    fonts-dejavu-core \
    fonts-liberation \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    XILINX_VERSION=2022.2 \
    XILINX_INSTALL_DIR=/opt/Xilinx \
    QT_X11_NO_MITSHM=1 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    NO_AT_BRIDGE=1

# Create a user that can match the host UID/GID for workspace file ownership and X11 local-user access.
RUN existing_group="$(awk -F: -v gid="${USER_GID}" '$3 == gid { print $1; exit }' /etc/group)" \
    && if [[ -z "${existing_group}" ]]; then groupadd --gid "${USER_GID}" "${USERNAME}"; existing_group="${USERNAME}"; fi \
    && if ! id -u "${USERNAME}" >/dev/null 2>&1; then useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; fi \
    && usermod -aG sudo,dialout,plugdev "${USERNAME}" || true \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-${USERNAME} \
    && chmod 0440 /etc/sudoers.d/90-${USERNAME} \
    && mkdir -p /opt/Xilinx /workspace /installers /config /licenses \
    && chown -R "${USERNAME}:${USER_GID}" /workspace /home/${USERNAME}

COPY scripts/install-vitis-vivado.sh /usr/local/bin/install-vitis-vivado.sh
COPY scripts/xilinx-entrypoint.sh /usr/local/bin/xilinx-entrypoint.sh
COPY scripts/xilinx-env.sh /usr/local/bin/xilinx-env.sh
RUN chmod +x /usr/local/bin/install-vitis-vivado.sh \
    /usr/local/bin/xilinx-entrypoint.sh \
    /usr/local/bin/xilinx-env.sh

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/xilinx-entrypoint.sh"]
CMD ["bash"]
