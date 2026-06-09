# Optional installer config

The install script will use this file if it exists:

```text
config/install_config.txt
```

The most reliable way to create it is from the AMD/Xilinx installer itself:

```bash
./xsetup -b ConfigGen
```

Then copy the generated file here as:

```text
config/install_config.txt
```

If `config/install_config.txt` is not present, the Docker install service tries this default command-line install:

```bash
xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms \
  --batch Install \
  --edition "Vitis Unified Software Platform" \
  --location /opt/Xilinx
```
