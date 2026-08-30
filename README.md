# paseo-nix-image

[Paseo](https://github.com/getpaseo/paseo) daemon with opencode and gh, built with Nix.

```sh
docker run -p 6767:6767 \
  -v paseo:/home/paseo/.paseo \
  -v opencode-config:/home/paseo/.config/opencode \
  -v opencode-data:/home/paseo/.local/share/opencode \
  -v "$PWD":/workspace \
  ghcr.io/nicolaschan/paseo-nix-image
```

Web UI at http://localhost:6767.
