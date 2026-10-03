-- Run from feather-weapons: lua tests/restart_ordering.lua
-- Exercise the real client-ready handler while startup yields.
local handlers, events, clock = {}, {}, 0
Config = { DevMode = false }
GetGameTimer = function() return clock end
Wait = function(ms) clock = clock + ms; coroutine.yield() end
RegisterNetEvent = function(name, handler) handlers[name] = handler end
AddEventHandler = function() end
TriggerClientEvent = function(name, target) events[#events + 1] = { name, target } end
FeatherCore = { RPC = { Register = function() end } }
CoreAdapter = { ResolveSession = function()
    return { ok = true, value = { source = 1, sessionId = 'test' } }
end }
local runtime = { sessionId = 'test', slots = {} }
WeaponRuntime = { Get = function() return runtime end }
dofile('server/services/reconciliation.lua')
source = 1
local handler = handlers['feather-weapons:server:client-ready']
local pending = coroutine.create(handler)
assert(coroutine.resume(pending))
assert(#events == 0, 'Existing partial runtime must not notify the client')
runtime.slots.throwable_nonary = { itemInstanceId = 87, ammo = 7 }
ReconciliationService.MarkStartupReady()
assert(coroutine.resume(pending))
assert(coroutine.status(pending) == 'dead')
assert(#events == 1 and events[1][1] == 'feather-weapons:client:runtime-ready')
assert(runtime.slots.throwable_nonary.ammo == 7, 'Handshake preserves restored ownership')
assert(handler() == nil and #events == 2, 'Repeated handshake works after readiness')
-- A fresh service instance that never finishes startup must fail closed.
dofile('server/services/reconciliation.lua')
local timeout = coroutine.create(handlers['feather-weapons:server:client-ready'])
while coroutine.status(timeout) ~= 'dead' do assert(coroutine.resume(timeout)) end
assert(#events == 2, 'Startup timeout must not publish partial state')
print('Restart ordering regression checks passed')
