---@meta

---@class FeatherWeaponsDiagnosticState
---@field equipped boolean
---@field itemInstanceId? integer|string
---@field definitionId? string
---@field nativeWeaponName? string
---@field nativeAmmoName? string
---@field generation? integer
---@field sessionId? string
---@field offhand? table

---@class FeatherWeaponsClientApi
---@field GetDiagnosticState fun(): FeatherWeaponsDiagnosticState

---@type FeatherWeaponsClientApi
FeatherWeaponsClient = {}
