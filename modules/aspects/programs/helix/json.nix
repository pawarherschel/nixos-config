# helix.json — JSON language config.
_: {
  den.aspects.programs.helix.json.homeManager = {
    programs.helix.languages.language = [
      {
        name = "json";
        language-servers = [
          {
            name = "vscode-json-language-server";
            except-features = [ "format" ];
          }
          "biome"
        ];
        auto-format = true;
      }
    ];
  };
}
