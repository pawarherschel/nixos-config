# OMP traits plugin — jj is the extension's only external executable.
{ den, ... }:
{
  den.aspects.programs.omp.homeManager =
    { pkgs, ... }:
    {
      wrappers.omp.runtimePkgs = [ pkgs.jujutsu ];
    };
}
