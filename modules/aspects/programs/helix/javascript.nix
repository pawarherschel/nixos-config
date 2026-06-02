# helix.javascript — JavaScript/TypeScript/JSX/TSX language configs.
_: {
  den.aspects.programs.helix.javascript.homeManager = {
    programs.helix.languages.language = [
      {
        name = "javascript";
        language-servers = [
          {
            name = "typescript-language-server";
            except-features = [ "format" ];
          }
          "biome"
        ];
        auto-format = true;
      }
      {
        name = "typescript";
        language-servers = [
          {
            name = "typescript-language-server";
            except-features = [ "format" ];
          }
          "biome"
        ];
        auto-format = true;
      }
      {
        name = "jsx";
        language-servers = [
          {
            name = "typescript-language-server";
            except-features = [ "format" ];
          }
          "biome"
        ];
        auto-format = true;
      }
      {
        name = "tsx";
        language-servers = [
          {
            name = "typescript-language-server";
            except-features = [ "format" ];
          }
          "biome"
        ];
        auto-format = true;
      }
    ];
  };
}
