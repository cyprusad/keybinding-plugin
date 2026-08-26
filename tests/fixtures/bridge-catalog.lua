return {
  schemaVersion = 1,
  sourceHash = "sha256:test",
  modifierCodes = {
    SUPER = { 133, 134 },
    SHIFT = { 50, 62 },
    CTRL = { 37, 105 },
    ALT = { 64, 108 }
  },
  matches = {
    ["SUPER|36|press|"] = "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    ["SUPER|36|release|"] = "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    ["SUPER|20|press|resize"] = "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
  }
}
