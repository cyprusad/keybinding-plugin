local root = arg[1]
local callbacks, payloads, dispatching = {}, {}, false
hl = {
  on = function(name, callback) callbacks[name] = callback end,
  dsp = { event = function(value) return value end },
  dispatch = function(value) payloads[#payloads + 1] = value end,
}
X = function(name, event) assert(callbacks[name], "missing callback: " .. name); callbacks[name](event) end
assert(pcall(dofile, root .. "/bridge.lua"))
local count = 0
for _ in pairs(callbacks) do count = count + 1 end
assert(count == 2)
X("input.keyboard.key", { keycode = 133, state = 1 })
X("input.keyboard.key", { keycode = 133, state = 1 })
X("input.keyboard.key", { keycode = 36, state = 1 })
X("input.keyboard.key", { keycode = 36, state = 0 })
X("keybinds.submap", "resize")
X("input.keyboard.key", { keycode = 20, state = 1 })
X("input.keyboard.key", { keycode = 133, state = 0 })
assert(payloads[1] == "omakeez:v1:guide:down:SUPER")
assert(payloads[2]:match(":match:sha256:a") ~= nil)
assert(payloads[3]:match(":match:sha256:b") ~= nil)
assert(payloads[4]:match(":match:sha256:c") ~= nil)
assert(payloads[5] == "omakeez:v1:guide:up")
X("input.keyboard.key", { keycode = 64, state = 1 })
X("input.keyboard.key", { keycode = 50, state = 1 })
X("input.keyboard.key", { keycode = 50, state = 0 })
X("input.keyboard.key", { keycode = 64, state = 0 })
assert(payloads[6] == "omakeez:v1:guide:down:ALT")
assert(payloads[7] == "omakeez:v1:mods:SHIFT_ALT")
assert(payloads[8] == "omakeez:v1:mods:ALT")
assert(payloads[9] == "omakeez:v1:guide:up")
for _ = 1, 10000 do X("input.keyboard.key", { keycode = 10, state = 1 }) end
assert(#payloads == 9)
local before = count
assert(pcall(dofile, root .. "/bridge.lua"))
local after = 0
for _ in pairs(callbacks) do after = after + 1 end
assert(before == after)
