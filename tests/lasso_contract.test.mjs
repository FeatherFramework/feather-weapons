import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const read = path => readFileSync(new URL('../' + path, import.meta.url), 'utf8');
const constants = read('shared/constants.lua');
assert.match(constants, /UtilitySlots = \{ utility = true, utility_secondary = true, utility_tertiary = true, utility_quaternary = true, utility_quinary = true, utility_senary = true, utility_septenary = true, utility_octonary = true \}/);
assert.match(constants, /WeaponSlots = \{\s*utility = true/);
assert.doesNotMatch(constants.match(/MeleeSlots = \{([^}]*)\}/s)[1], /utility/);
assert.doesNotMatch(constants.match(/ThrowableSlots = \{([^}]*)\}/s)[1], /utility/);
assert.match(read('config.lua'), /utility = "weapon_utility"/);
assert.match(read('config.lua'), /utilitySlots = \{ "utility", "utility_secondary", "utility_tertiary", "utility_quaternary", "utility_quinary", "utility_senary","utility_septenary", "utility_octonary" \}/);
assert.match(read('config.lua'), /utility_secondary = "weapon_utility_secondary"/);
const lasso = read('shared/definitions/weapons.lua').match(/utility_lasso = \{([\s\S]*?)\n    melee_knife/)[1];
for (const expected of ['WEAPON_LASSO', 'usesAmmunition = false', 'capacity = 0', 'slot = "utility"']) {
  assert.ok(lasso.includes(expected), expected);
}
assert.match(read('server/adapters/feather_inventory.lua'), /configured.utility or "weapon_utility"/);
assert.match(read('server/services/runtime.lua'), /utility = true/);
assert.match(read('client/main.lua'), /'melee_quinary', 'utility'/);
assert.match(read('server/services/equip.lua'), /WeaponConstants.UtilitySlots\[slot\] and "utility"/);
assert.match(read('server/services/equip.lua'), /Only one lasso can be equipped/);
assert.match(read('server/services/commands.lua'), /definitions.weapon == 49/);
assert.match(read('shared/definitions/weapons.lua'), /nativeWeaponName = "WEAPON_LASSO_REINFORCED"/);
assert.match(read('server/adapters/feather_inventory.lua'), /configured.utility_secondary or "weapon_utility_secondary"/);
assert.match(read('client/main.lua'), /'utility', 'utility_secondary'/);
assert.doesNotMatch(read('sql/add_reinforced_lasso.sql'), /item_ammo/);
assert.doesNotMatch(read('sql/add_lasso.sql'), /item_ammo/);
console.log('Lasso static slot/catalog/seed contracts passed (not a Lua runtime test).');
const lantern = read('shared/definitions/weapons.lua').match(/utility_davy_lantern = \{([\s\S]*?)\n    \},/)[1];
for (const expected of ['WEAPON_MELEE_DAVY_LANTERN', 'usesAmmunition = false', 'capacity = 0', 'family = "lantern"']) {
  assert.ok(lantern.includes(expected), expected);
}
assert.doesNotMatch(read('shared/definitions/weapons.lua'), /utility_lantern =/);
assert.doesNotMatch(read('sql/install_items.sql'), /'weapon_utility_lantern'/);
console.log('Lantern static ammunition-free catalog/seed checks passed.');

assert.match(read('shared/definitions/weapons.lua'), /nativeWeaponName = "WEAPON_MELEE_DAVY_LANTERN"/);
assert.doesNotMatch(read('sql/add_davy_lantern.sql'), /item_ammo/);
console.log('Davy Lantern static catalog checks passed.');

assert.match(read('config.lua'), /utility_tertiary = "weapon_utility_tertiary"/);
assert.match(read('server/adapters/feather_inventory.lua'), /configured.utility_tertiary/);
assert.match(read('client/main.lua'), /'utility_secondary', 'utility_tertiary'/);
assert.match(read('shared/definitions/weapons.lua'), /nativeWeaponName = "WEAPON_KIT_BINOCULARS"/);
assert.doesNotMatch(read('sql/add_binoculars.sql'), /item_ammo/);
console.log('Binoculars static slot/catalog checks passed.');

assert.match(read('config.lua'), /utility_quaternary = "weapon_utility_quaternary"/);
assert.match(read('server/adapters/feather_inventory.lua'), /configured.utility_quaternary/);
assert.match(read('client/main.lua'), /'utility_tertiary', 'utility_quaternary'/);
assert.match(read('shared/definitions/weapons.lua'), /nativeWeaponName = "WEAPON_KIT_CAMERA"/);
assert.doesNotMatch(read('sql/add_camera.sql'), /item_ammo/);
console.log('Camera static slot/catalog checks passed.');

assert.match(read('config.lua'), /utility_quinary = "weapon_utility_quinary"/);
assert.match(read('server/adapters/feather_inventory.lua'), /configured.utility_quinary/);
assert.match(read('client/main.lua'), /'utility_quaternary', 'utility_quinary'/);
assert.match(read('shared/definitions/weapons.lua'), /nativeWeaponName = "WEAPON_KIT_CAMERA_ADVANCED"/);
assert.doesNotMatch(read('sql/add_advanced_camera.sql'), /item_ammo/);
console.log('Advanced Camera static slot/catalog checks passed.');

assert.match(read('config.lua'), /utility_senary = "weapon_utility_senary"/);
assert.match(read('server/adapters/feather_inventory.lua'), /configured.utility_senary/);
assert.match(read('client/main.lua'), /'utility_quinary', 'utility_senary'/);
assert.doesNotMatch(read('shared/definitions/weapons.lua'), /utility_lantern_electric =/);
assert.doesNotMatch(read('sql/install_items.sql'), /'weapon_utility_lantern_electric'/);
assert.doesNotMatch(read('sql/add_electric_lantern.sql'), /item_ammo/);
console.log('Electric Lantern retirement/static slot checks passed.');

assert.doesNotMatch(read('shared/definitions/weapons.lua'), /utility_torch =/);
assert.doesNotMatch(read('sql/install_items.sql'), /'weapon_utility_torch'/);
console.log('Torch retirement static checks passed.');

assert.match(read('config.lua'), /melee_quinary = "weapon_melee_quinary"/);
assert.match(constants, /melee_quaternary = true, melee_quinary = true/);
assert.match(read('server/adapters/feather_inventory.lua'), /configured.melee_quinary/);
assert.match(read('client/main.lua'), /'melee_quaternary', 'melee_quinary'/);
assert.match(read('shared/definitions/weapons.lua'), /nativeWeaponName = "WEAPON_MELEE_HAMMER"/);
assert.doesNotMatch(read('sql/add_hammer.sql'), /item_ammo/);
console.log('Hammer static melee-slot/catalog checks passed.');

const improvedBinoculars = read('shared/definitions/weapons.lua').match(/utility_binoculars_improved = \{([\s\S]*?)\n    utility_camera =/)[1];
assert.match(improvedBinoculars, /nativeWeaponName = "WEAPON_KIT_BINOCULARS_IMPROVED"/);
assert.match(improvedBinoculars, /usesAmmunition = false/);
assert.match(improvedBinoculars, /capacity = 0/);
assert.match(read('sql/add_improved_binoculars.sql'), /'item_weapon', 'unique'/);
assert.doesNotMatch(read('sql/add_improved_binoculars.sql'), /item_ammo/);
assert.match(read('sql/install_items.sql'), /weapon_utility_binoculars_improved/);
console.log('Improved Binoculars static equipment/catalog checks passed.');

assert.match(read('config.lua'), /utility_septenary = "weapon_utility_septenary"/);
assert.match(read('server/adapters/feather_inventory.lua'), /configured.utility_septenary/);
assert.match(read('client/main.lua'), /ApplySlotMaintenance\('utility_septenary', extraSlots.utility_septenary\)/);
const detector = read('shared/definitions/weapons.lua').match(/utility_metal_detector = \{([\s\S]*?)\n    utility_camera =/)[1];
assert.match(detector, /nativeWeaponName = "WEAPON_KIT_METAL_DETECTOR"/);
assert.match(detector, /usesAmmunition = false/);
assert.match(detector, /capacity = 0/);
assert.doesNotMatch(read('sql/add_metal_detector.sql'), /item_ammo/);
console.log('Metal Detector static slot/catalog checks passed.');

assert.match(read('config.lua'), /utility_octonary = "weapon_utility_octonary"/);
assert.match(read('server/adapters/feather_inventory.lua'), /configured.utility_octonary/);
assert.match(read('client/main.lua'), /ApplySlotMaintenance\('utility_octonary', extraSlots.utility_octonary\)/);
const rod = read('shared/definitions/weapons.lua').match(/utility_fishing_rod = \{([\s\S]*?)\n    utility_camera =/)[1];
assert.match(rod, /nativeWeaponName = "WEAPON_FISHINGROD"/);
assert.match(rod, /usesAmmunition = false/);
assert.match(rod, /capacity = 0/);
assert.doesNotMatch(read('sql/add_fishing_rod.sql'), /item_ammo/);
console.log('Fishing Rod static slot/catalog checks passed.');
