{
  # I'm here flaking my OS
  description = "Vulture NixOS";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Both opencode generations (v1 `opencode`, v2 `opencode2`) come from
    # numtide/llm-agents.nix. Do not follow its nixpkgs: its packages are
    # prebuilt/substituted against its own locked nixpkgs-unstable.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    {
      nixosConfigurations.vulture-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.rudlorenz = import ./home.nix;

            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
}
