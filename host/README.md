# Host-side X11 helpers

Run these on the Linux host, not inside the container.

```bash
./host/enable-x11.sh
```

Then run a GUI app:

```bash
docker compose run --rm xilinx-x11 xeyes
docker compose run --rm xilinx-x11 vivado
```

Revoke the access entry when finished:

```bash
./host/disable-x11.sh
```
