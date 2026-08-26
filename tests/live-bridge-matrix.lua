-- Exercise every unique entry in a generated live bridge catalog without
-- dispatching the operator's real (and potentially disruptive) commands.
local root = assert(arg[1], "usage: lua tests/live-bridge-matrix.lua ROOT CATALOG")
local catalog_path = assert(arg[2], "usage: lua tests/live-bridge-matrix.lua ROOT CATALOG")

local callbacks = {}
local payloads = {}
hl = {
  on = function(name, callback) callbacks[name] = callback end,
  dsp = { event = function(value) return value end },
  dispatch = function(value) payloads[#payloads + 1] = value end,
}

assert(pcall(dofile, root .. "/bridge.lua"))
local catalog = assert(dofile(catalog_path))
local on_key = assert(callbacks["input.keyboard.key"], "keyboard callback was not registered")
local on_submap = assert(callbacks["keybinds.submap"], "submap callback was not registered")

local modifier_order = { "SUPER", "SHIFT", "CTRL", "ALT" }
local held = {}

local function clear_payloads()
  payloads = {}
end

local function set_modifiers(mask)
  local wanted = {}
  for name in mask:gmatch("[^_]+") do wanted[name] = true end

  for i = #modifier_order, 1, -1 do
    local name = modifier_order[i]
    if held[name] and not wanted[name] then
      on_key(catalog.modifierCodes[name][1], 0, 0)
      held[name] = nil
    end
  end
  for _, name in ipairs(modifier_order) do
    if wanted[name] and not held[name] then
      on_key(catalog.modifierCodes[name][1], 0, 1)
      held[name] = true
    end
  end
end

local keys = {}
for key in pairs(catalog.matches) do keys[#keys + 1] = key end
table.sort(keys)

local exercised = 0
local modifier_masks = {}
local phases = {}
local submaps = {}

for _, match_key in ipairs(keys) do
  local mask, code_text, phase, submap = match_key:match("^([^|]*)|([^|]+)|([^|]+)|(.*)$")
  local code = tonumber(code_text)
  assert(mask and code and (phase == "press" or phase == "release"), "invalid match key: " .. match_key)

  local modifier_key = false
  for _, name in ipairs(modifier_order) do
    for _, modifier_code in ipairs(catalog.modifierCodes[name]) do
      if code == modifier_code then modifier_key = true end
    end
  end

  if not modifier_key then
    set_modifiers(mask)
    on_submap(submap)
    clear_payloads()
    on_key(code, 0, phase == "press" and 1 or 0)

    local expected = "keybind-dojo:v1:match:" .. catalog.matches[match_key] .. ":" .. phase
    assert(#payloads == 1, match_key .. " emitted " .. #payloads .. " payloads")
    assert(payloads[1] == expected, match_key .. " emitted an unexpected payload")

    exercised = exercised + 1
    modifier_masks[mask] = true
    phases[phase] = true
    submaps[submap] = true
  end
end

set_modifiers("")

local function table_size(value)
  local count = 0
  for _ in pairs(value) do count = count + 1 end
  return count
end

assert(exercised >= 50, "fewer than 50 unique live matches were exercised")
print(string.format(
  "live_bridge_matrix=pass matches=%d modifier_masks=%d phases=%d submaps=%d",
  exercised,
  table_size(modifier_masks),
  table_size(phases),
  table_size(submaps)
))
