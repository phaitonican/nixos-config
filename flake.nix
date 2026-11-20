{
  description = "NixOS configuration for host \"nixos\"";

  # Usage:
  #   sudo nixos-rebuild switch --flake .#nixos
  #   sudo nixos-rebuild build  --flake .#nixos
  #   nix flake update            # update the pinned nixpkgs revision
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./configuration.nix ];
      };

      # `nix build` builds the complete system closure.
      packages.${system}.default = self.nixosConfigurations.nixos.config.system.build.toplevel;

      # `nix fmt` formats the Nix files in this repository.
      formatter.${system} = pkgs.nixfmt;
    };
}
