# Vitis/Vivado 2022.2 Docker setup — Ubuntu 22.04 + persistent install + Linux X11 GUI

This setup uses two persistent layers:

1. A Docker image based on `ubuntu:22.04` with OS/runtime libraries needed by Vitis/Vivado and Linux X11 GUI access.
2. A named Docker volume mounted at `/opt/Xilinx` so the large AMD/Xilinx install persists across containers.

The AMD/Xilinx installer is not included. Place your legally downloaded 2022.2 installer under `./installers`.

## Directory layout

```text
.
├── Dockerfile
├── docker-compose.yml
├── host/
│   ├── enable-x11.sh
│   └── disable-x11.sh
├── installers/
│   └── put the AMD/Xilinx 2022.2 installer here
├── config/
│   ├── README.md
│   └── install_config.example.txt
├── licenses/
│   └── optional local license files
└── workspace/
    └── your projects go here
```

## Supported installer inputs

Place one of these under `./installers`:

- extracted installer directory containing `xsetup`
- 2022.2 SFD/offline `.tar.gz`
- 2022.2 Linux self-extracting `.bin`

For repeatable installs, prefer the full SFD/offline installer.

## Build the base image

```bash
cp .env.example .env
sed -i "s/HOST_UID=1000/HOST_UID=$(id -u)/" .env
sed -i "s/HOST_GID=1000/HOST_GID=$(id -g)/" .env

# Optional, but useful for serial/JTAG permissions on Linux hosts:
sed -i "s/DIALOUT_GID=20/DIALOUT_GID=$(getent group dialout | cut -d: -f3 || echo 20)/" .env
sed -i "s/PLUGDEV_GID=46/PLUGDEV_GID=$(getent group plugdev | cut -d: -f3 || echo 46)/" .env

docker compose build
```

The image user is created with your host UID/GID. That matters for workspace file ownership and also makes local X11 authorization cleaner.

## Install Vitis/Vivado into the persistent Docker volume

```bash
docker compose run --rm xilinx-install
```

This populates the named volume:

```text
xilinx-2022_2 -> /opt/Xilinx
```

The install is retained until you explicitly remove the volume.

## Start an interactive non-GUI shell

```bash
docker compose run --rm xilinx-shell
```

Inside the container:

```bash
which vivado
vivado -version
which vitis
```

The entrypoint automatically sources:

```text
/opt/Xilinx/Vitis/2022.2/settings64.sh
```

or falls back to:

```text
/opt/Xilinx/Vivado/2022.2/settings64.sh
```

## Linux X11 GUI: local desktop

On the Linux host, allow your local user to connect to the X server:

```bash
./host/enable-x11.sh
```

That helper runs the narrower form of `xhost` for your current local user. The equivalent manual command is:

```bash
xhost +SI:localuser:$(id -un)
```

Test X11 forwarding first:

```bash
docker compose run --rm xilinx-x11 xeyes
```

Then launch Vivado:

```bash
docker compose run --rm xilinx-x11 vivado
```

Or launch Vitis:

```bash
docker compose run --rm xilinx-x11 vitis
```

For a shell that can launch either GUI manually:

```bash
docker compose run --rm xilinx-x11 bash
vivado
```

When done, revoke the X11 permission:

```bash
./host/disable-x11.sh
```

The equivalent manual command is:

```bash
xhost -SI:localuser:$(id -un)
```

If your host X server still refuses the connection, use the broader lab-only fallback:

```bash
xhost +local:
docker compose run --rm xilinx-x11 vivado
xhost -local:
```

Do not use the fallback on an untrusted multi-user host.

## Linux X11 GUI plus USB/JTAG access

Use this service for Vivado Hardware Manager, `hw_server`, `xsdb`, or `xsct` workflows that need access to FPGA cables/JTAG probes.

On the host:

```bash
./host/enable-x11.sh
```

Then run:

```bash
docker compose run --rm xilinx-x11-hw vivado
```

This maps the host USB bus and allows common USB/JTAG/serial character-device majors using `device_cgroup_rules`:

```yaml
volumes:
  - /dev/bus/usb:/dev/bus/usb:rw

device_cgroup_rules:
  - "c 189:* rwm"   # USB bus
  - "c 188:* rwm"   # /dev/ttyUSB*
  - "c 166:* rwm"   # /dev/ttyACM*
```

Host udev rules and permissions still matter. For FPGA cables/JTAG, install or configure cable-driver/udev permissions on the Linux host. The container can expose USB devices, but it does not replace host-side permissions.

## Linux SSH X11 forwarding

Use this only when you are SSH'd into the Linux host with `ssh -X` or `ssh -Y` and your `DISPLAY` looks like `localhost:10.0`.

Create an Xauthority file for Docker:

```bash
rm -f /tmp/.docker.xauth
touch /tmp/.docker.xauth
xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -
chmod 644 /tmp/.docker.xauth
```

Then run:

```bash
docker compose run --rm xilinx-x11-ssh vivado
```

The `xilinx-x11-ssh` service uses `network_mode: host` so the container can reach the SSH-forwarded X11 listener on the host.

## License server or license files

If you use a floating license, set it in `.env`:

```text
XILINXD_LICENSE_FILE=2100@your-license-server
LM_LICENSE_FILE=2100@your-license-server
```

If you use a local license file, put it under `./licenses` and point the variable at the mounted path, for example:

```text
XILINXD_LICENSE_FILE=/licenses/Xilinx.lic
LM_LICENSE_FILE=/licenses/Xilinx.lic
```

## Remove the persisted install

```bash
docker compose down
docker volume rm xilinx-2022_2
```

To remove GUI/home preferences too:

```bash
docker volume rm xilinx-home-2022_2
```

Do **not** use `docker compose down -v` unless you intend to delete the persisted install volume.
