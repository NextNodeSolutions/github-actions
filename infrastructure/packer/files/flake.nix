{
  description = "NixOS configuration for Dokploy server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-dokploy = {
      url = "github:el-kurto/nix-dokploy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-dokploy, ... }: {
    nixosConfigurations.dokploy-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-dokploy.nixosModules.default
        ./configuration.nix
        ./hardware-configuration.nix
      ];
    };
  };
}
