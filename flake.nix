{
  # I'm here flaking my OS
  description = "Vulture NixOS";

  inputs = {
    # TODO: find a way to set release version as a variable
    nixpkgs.url = "nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    {
      nixosConfigurations.vulture-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.rudlorenz = import ./home.nix;
          }
        ];
      };
    };
}
