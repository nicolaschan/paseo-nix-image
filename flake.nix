{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default-linux";
    paseo.url = "github:getpaseo/paseo";
    llm-agents.url = "github:numtide/llm-agents.nix";
    agent-images.url = "github:nothingnesses/agent-images";
  };

  outputs =
    {
      nixpkgs,
      systems,
      paseo,
      llm-agents,
      agent-images,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          mkAgentImage = agent-images.lib.mkAgentImage { inherit pkgs; };
          paseoWithPty = paseo.packages.${system}.paseo.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              ptyDir=$(find . -type d -path '*/node-pty/prebuilds' -print -quit)
              if [ -z "$ptyDir" ]; then
                echo "node-pty prebuilds not found in build tree" >&2
                exit 1
              fi
              outPty="$out/lib/paseo/packages/server/node_modules/node-pty/prebuilds"
              mkdir -p "$outPty"
              cp -r "$ptyDir"/linux-* "$outPty/"
            '';
          });
        in
        {
          docker = mkAgentImage {
            name = "paseo";
            agent = paseoWithPty;
            entrypoint = [
              "paseo"
              "daemon"
              "start"
              "--foreground"
            ];
            extraPackages = [
              llm-agents.packages.${system}.opencode
              pkgs.gh
              pkgs.procps
              pkgs.lbzip2
            ];
            user = "paseo";
            extraDirectories = [
              "~/.paseo"
              "~/.config/opencode"
              "~/.local/share/opencode"
            ];
            extraEnv = {
              PASEO_HOME = "/home/paseo/.paseo";
              PASEO_LISTEN = "0.0.0.0:6767";
              PASEO_WEB_UI_ENABLED = "true";
            };
            withNix = true;
          };
        }
      );
    };
}
