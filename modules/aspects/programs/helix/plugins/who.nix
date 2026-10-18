# who.hx obtains blame information from Git.
{ ... }:
{
  den.aspects.programs.helix.homeManager =
    { pkgs, ... }:
    {
      programs.nhx = {
        requiredPackages = [ pkgs.git ];
        plugins.who.enable = true;
      };
    };
}
