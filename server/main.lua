local function FailStartup(message, details)
    print(("[feather-weapons] startup failed: %s"):format(message))
    if details and Config.DevMode then print(json.encode(details)) end
    if Config.StrictStartup then error(message) end
end

local coreResult = CoreAdapter.CheckCapabilities()
if not coreResult.ok then
    FailStartup(coreResult.error.message, coreResult.error.details)
    return
end

local definitionResult = DefinitionRegistry.Start()
if not definitionResult.ok then
    FailStartup(definitionResult.error.message, definitionResult.error.details)
    return
end

local testProviderResult = InstallTestInventoryProvider()
if testProviderResult and not testProviderResult.ok then
    FailStartup(testProviderResult.error.message, testProviderResult.error.details)
    return
end

ReconciliationService.BootstrapActiveSessions()

local counts = definitionResult.value
print(("[feather-weapons] foundation ready: %d weapon, %d ammunition, %d attachment definitions")
    :format(counts.weapon, counts.ammunition, counts.attachment))

if InventoryAdapter.IsReady() then
    print("[feather-weapons] development inventory provider active")
else
    print("[feather-weapons] inventory provider pending; persistence and equip features remain disabled")
end
