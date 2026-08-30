-- Omakeez's deliberately small Hyprland input observer.
local STATE_NAME = "__omakeez_bridge_state"
local ORDERED_MODIFIERS = { "SUPER", "SHIFT", "CTRL", "ALT" }

local state_home = os.getenv("XDG_STATE_HOME")
if not state_home or state_home == "" then
  state_home = (os.getenv("HOME") or "") .. "/.local/state"
end

local function valid_codes(codes)
  if type(codes) ~= "table" or #codes == 0 then return false end
  for _, code in ipairs(codes) do
    if type(code) ~= "number" or code < 1 then return false end
  end
  return true
end

local function empty_modifiers()
  return { SUPER = {}, SHIFT = {}, CTRL = {}, ALT = {} }
end

local function load_catalog()
  local loaded, catalog = pcall(dofile, state_home .. "/omarchy/omakeez/bridge-catalog.lua")
  if not loaded or type(catalog) ~= "table" or catalog.schemaVersion ~= 1
    or type(catalog.matches) ~= "table" then return nil, nil end

  local modifier_codes = catalog.modifierCodes
  if type(modifier_codes) ~= "table" then return nil, nil end

  local modifiers = empty_modifiers()
  for _, name in ipairs(ORDERED_MODIFIERS) do
    local codes = modifier_codes[name]
    if not valid_codes(codes) then return nil, nil end
    for _, code in ipairs(codes) do modifiers[name][code] = true end
  end
  return catalog, modifiers
end

local existing = rawget(_G, STATE_NAME)
if type(existing) == "table" then
  local catalog, modifiers = load_catalog()
  existing.enabled = catalog ~= nil
  existing.catalog = catalog
  existing.modifiers = modifiers or empty_modifiers()
  existing.held = { SUPER = {}, SHIFT = {}, CTRL = {}, ALT = {} }
  existing.submap = ""
  existing.guideRoot = nil
  return
end

local bridge = {
  enabled = false,
  catalog = nil,
  modifiers = empty_modifiers(),
  held = { SUPER = {}, SHIFT = {}, CTRL = {}, ALT = {} },
  submap = "",
  guideRoot = nil,
  emitting = false,
}
_G[STATE_NAME] = bridge

local function refresh_catalog()
  local catalog, modifiers = load_catalog()
  if not catalog then
    bridge.enabled = false
    bridge.catalog = nil
    bridge.modifiers = empty_modifiers()
    return false
  end
  bridge.enabled = true
  bridge.catalog = catalog
  bridge.modifiers = modifiers
  return true
end

refresh_catalog()

local function valid_id(value)
  return type(value) == "string"
    and #value == 71
    and value:match("^sha256:[0-9a-f]+$") ~= nil
end

local function emit(payload)
  if not bridge.enabled or bridge.emitting then return end
  bridge.emitting = true
  pcall(function() hl.dispatch(hl.dsp.event(payload)) end)
  bridge.emitting = false
end

local function is_held(name)
  for _, value in pairs(bridge.held[name]) do
    if value then return true end
  end
  return false
end

local function modifier_mask()
  local names = {}
  for _, name in ipairs(ORDERED_MODIFIERS) do
    if is_held(name) then names[#names + 1] = name end
  end
  return table.concat(names, "_")
end

local function event_value(event, key, fallback)
  if type(event) ~= "table" then return fallback end
  local value = event[key]
  if value == nil then return fallback end
  return value
end

hl.on("input.keyboard.key", function(keycode, timestamp, event_state)
  if not bridge.enabled and not refresh_catalog() then return end
  local code, state
  if type(keycode) == "table" then
    code = tonumber(event_value(keycode, "keycode", event_value(keycode, "code", 0)))
    state = tonumber(event_value(keycode, "state", -1))
  else
    code = tonumber(keycode)
    state = tonumber(event_state)
  end
  if not code or (state ~= 0 and state ~= 1) then return end

  for _, name in ipairs(ORDERED_MODIFIERS) do
    if bridge.modifiers[name][code] then
      local was_held = is_held(name)
      local was_empty = modifier_mask() == ""
      if state == 1 then
        if bridge.held[name][code] then return end
        bridge.held[name][code] = true
        if was_empty then
          bridge.guideRoot = name
          emit("omakeez:v1:guide:down:" .. name)
        end
      else
        if not bridge.held[name][code] then return end
        bridge.held[name][code] = nil
        if name == bridge.guideRoot and was_held and not is_held(name) then
          bridge.guideRoot = nil
          emit("omakeez:v1:guide:up")
          return
        end
      end
      if bridge.guideRoot and not was_empty then
        emit("omakeez:v1:mods:" .. modifier_mask())
      end
      return
    end
  end

  local phase = state == 1 and "press" or "release"
  local key = modifier_mask() .. "|" .. tostring(code) .. "|" .. phase .. "|" .. bridge.submap
  local id = bridge.catalog.matches[key]
  if valid_id(id) then emit("omakeez:v1:match:" .. id .. ":" .. phase) end
end)

hl.on("keybinds.submap", function(event)
  if not bridge.enabled then return end
  if type(event) == "table" then event = event.name or event.submap end
  if type(event) == "string" then bridge.submap = event end
end)
