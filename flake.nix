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
        in
        {
          docker = mkAgentImage {
            name = "paseo";
            agent = paseo.packages.${system}.paseo;
            entrypoint = [
              "paseo"
              "daemon"
              "start"
              "--foreground"
            ];
            extraPackages = [
              llm-agents.packages.${system}.opencode
              pkgs.gh
              pkgs.git
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
