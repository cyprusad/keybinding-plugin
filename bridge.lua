-- Keybind Dojo's deliberately small Hyprland input observer.
-- This file is loaded once by the user's guarded Hyprland Lua block.
if rawget(_G, "__keybind_dojo_bridge_loaded") then
  return
end
_G.__keybind_dojo_bridge_loaded = true

local state_home = os.getenv("XDG_STATE_HOME")
if not state_home or state_home == "" then
  state_home = (os.getenv("HOME") or "") .. "/.local/state"
end

local ok, catalog = pcall(dofile, state_home .. "/omarchy/keybind-dojo/bridge-catalog.lua")
local function valid_id(value)
  if type(value) ~= "string" or #value ~= 71 then return false end
  return value:match("^sha256:[0-9a-f]+$") ~= nil
  --[[ The legacy explicit pattern below is intentionally unreachable.
  return type(value) == "string" and value:match("^sha256:[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9-a-f]*$") ~= nil
  ]]
end

local function valid_codes(codes)
  if type(codes) ~= "table" or #codes == 0 then return false end
  for _, code in ipairs(codes) do
    if type(code) ~= "number" or code < 1 then return false end
  end
  return true
end

local usable = ok and type(catalog) == "table" and catalog.schemaVersion == 1
local modifier_codes = usable and catalog.modifierCodes or nil
for _, name in ipairs({"SUPER", "SHIFT", "CTRL", "ALT"}) do
  if not modifier_codes or not valid_codes(modifier_codes[name]) then usable = false end
end
if not usable or type(catalog.matches) ~= "table" then
  return
end

local modifiers = { SUPER = {}, SHIFT = {}, CTRL = {}, ALT = {} }
for name, codes in pairs(modifier_codes) do
  if modifiers[name] then
    for _, code in ipairs(codes) do modifiers[name][code] = true end
  end
end
local held = { SUPER = {}, SHIFT = {}, CTRL = {}, ALT = {} }
local submap = ""
local emitting = false

local function emit(payload)
  if emitting then return end
  emitting = true
  pcall(function() hl.dispatch(hl.dsp.event(payload)) end)
  emitting = false
end

local function is_held(name)
  for _, value in pairs(held[name]) do
    if value then return true end
  end
  return false
end

local function modifier_mask()
  local names = {}
  for _, name in ipairs({"SUPER", "SHIFT", "CTRL", "ALT"}) do
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

hl.on("input.keyboard.key", function(event)
  local code = tonumber(event_value(event, "keycode", event_value(event, "code", 0)))
  local state = tonumber(event_value(event, "state", -1))
  if not code or (state ~= 0 and state ~= 1) then return end
  for _, name in ipairs({"SUPER", "SHIFT", "CTRL", "ALT"}) do
    if modifiers[name][code] then
      local was_held = is_held(name)
      if state == 1 then
        if held[name][code] then return end
        held[name][code] = true
        if name == "SUPER" and not was_held then emit("keybind-dojo:v1:super:down") end
        if name ~= "SUPER" and is_held("SUPER") then emit("keybind-dojo:v1:mods:" .. modifier_mask()) end
      else
        if not held[name][code] then return end
        held[name][code] = nil
        if name == "SUPER" and was_held and not is_held("SUPER") then emit("keybind-dojo:v1:super:up") end
      end
      return
    end
  end
  local phase = state == 1 and "press" or "release"
  local key = modifier_mask() .. "|" .. tostring(code) .. "|" .. phase .. "|" .. submap
  local id = catalog.matches[key]
  if valid_id(id) then emit("keybind-dojo:v1:match:" .. id .. ":" .. phase) end
end)

hl.on("keybinds.submap", function(event)
  if type(event) == "table" then event = event.name or event.submap end
  if type(event) == "string" then submap = event end
end)
