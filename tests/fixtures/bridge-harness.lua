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
assert(payloads[1] == "keybind-dojo:v1:super:down")
assert(payloads[2]:match(":match:sha256:a") ~= nil)
assert(payloads[3]:match(":match:sha256:c") ~= nil)
assert(payloads[4] == "keybind-dojo:v1:super:up")
for _ = 1, 10000 do X("input.keyboard.key", { keycode = 10, state = 1 }) end
assert(#payloads == 4)
local before = count
assert(pcall(dofile, root .. "/bridge.lua"))
local after = 0
for _ in pairs(callbacks) do after = after + 1 end
assert(before == after)
