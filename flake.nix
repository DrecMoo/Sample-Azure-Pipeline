{
  description = "Sample Nixos config flake";

  inputs = {
    #Main NixOS packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    #Nixpkgs commit for .NET version
    nixpkgs-dotnet.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ...}@inputs:
    let 
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit pkgs;
          pkgs-dotnet = nixpkgs-dotnet;
        };
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./configuration.nix
        ];      
      };
    };
}