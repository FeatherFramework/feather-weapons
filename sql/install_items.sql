-- Existing installations: run rename_weapon_item_names.sql before this seed.

-- Standard firearm catalog. Match weapon definitions; preserve existing numeric IDs.
INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_pistol_volcanic', 'Volcanic Pistol', 'Volcanic Pistol.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_pistol_volcanic');

UPDATE `items` SET `display_name` = 'Volcanic Pistol', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_pistol_volcanic';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_pistol_m1899', 'M1899 Pistol', 'M1899 Pistol.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_pistol_m1899');

UPDATE `items` SET `display_name` = 'M1899 Pistol', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_pistol_m1899';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_pistol_semiauto', 'Semi-Automatic Pistol', 'Semi-Automatic Pistol.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_pistol_semiauto');

UPDATE `items` SET `display_name` = 'Semi-Automatic Pistol', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_pistol_semiauto';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_pistol_mauser', 'Mauser Pistol', 'Mauser Pistol.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_pistol_mauser');

UPDATE `items` SET `display_name` = 'Mauser Pistol', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_pistol_mauser';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_revolver_doubleaction', 'Double-Action Revolver', 'Double-Action Revolver.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_revolver_doubleaction');

UPDATE `items` SET `display_name` = 'Double-Action Revolver', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_revolver_doubleaction';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_revolver_lemat', 'LeMat Revolver', 'LeMat Revolver.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_revolver_lemat');

UPDATE `items` SET `display_name` = 'LeMat Revolver', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_revolver_lemat';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_revolver_navy', 'Navy Revolver', 'Navy Revolver.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_revolver_navy');

UPDATE `items` SET `display_name` = 'Navy Revolver', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_revolver_navy';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_repeater_carbine', 'Carbine Repeater', 'Carbine Repeater.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_repeater_carbine');

UPDATE `items` SET `display_name` = 'Carbine Repeater', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_repeater_carbine';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_repeater_lancaster', 'Lancaster Repeater', 'Lancaster Repeater.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_repeater_lancaster');

UPDATE `items` SET `display_name` = 'Lancaster Repeater', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_repeater_lancaster';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_repeater_henry', 'Litchfield Repeater', 'Litchfield Repeater.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_repeater_henry');

UPDATE `items` SET `display_name` = 'Litchfield Repeater', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_repeater_henry';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_repeater_evans', 'Evans Repeater', 'Evans Repeater.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_repeater_evans');

UPDATE `items` SET `display_name` = 'Evans Repeater', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_repeater_evans';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_rifle_springfield', 'Springfield Rifle', 'Springfield Rifle.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_rifle_springfield');

UPDATE `items` SET `display_name` = 'Springfield Rifle', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_rifle_springfield';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_rifle_boltaction', 'Bolt Action Rifle', 'Bolt Action Rifle.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_rifle_boltaction');

UPDATE `items` SET `display_name` = 'Bolt Action Rifle', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_rifle_boltaction';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_rifle_varmint', 'Varmint Rifle', 'Varmint Rifle.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_rifle_varmint');

UPDATE `items` SET `display_name` = 'Varmint Rifle', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_rifle_varmint';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_sniperrifle_rollingblock', 'Rolling Block Rifle', 'Rolling Block Rifle.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_sniperrifle_rollingblock');

UPDATE `items` SET `display_name` = 'Rolling Block Rifle', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_sniperrifle_rollingblock';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_sniperrifle_carcano', 'Carcano Rifle', 'Carcano Rifle.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_sniperrifle_carcano');

UPDATE `items` SET `display_name` = 'Carcano Rifle', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_sniperrifle_carcano';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_rifle_elephant', 'Elephant Rifle', 'Elephant Rifle.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_rifle_elephant');

UPDATE `items` SET `display_name` = 'Elephant Rifle', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_rifle_elephant';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_shotgun_doublebarrel', 'Double-Barreled Shotgun', 'Double-Barreled Shotgun.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_shotgun_doublebarrel');

UPDATE `items` SET `display_name` = 'Double-Barreled Shotgun', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_shotgun_doublebarrel';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_shotgun_sawedoff', 'Sawed-Off Shotgun', 'Sawed-Off Shotgun.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_shotgun_sawedoff');

UPDATE `items` SET `display_name` = 'Sawed-Off Shotgun', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_shotgun_sawedoff';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_shotgun_pump', 'Pump-Action Shotgun', 'Pump-Action Shotgun.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_shotgun_pump');

UPDATE `items` SET `display_name` = 'Pump-Action Shotgun', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_shotgun_pump';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_shotgun_semiauto', 'Semi-Auto Shotgun', 'Semi-Auto Shotgun.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_shotgun_semiauto');

UPDATE `items` SET `display_name` = 'Semi-Auto Shotgun', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_shotgun_semiauto';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_shotgun_repeating', 'Repeating Shotgun', 'Repeating Shotgun.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_shotgun_repeating');

UPDATE `items` SET `display_name` = 'Repeating Shotgun', `usable` = 1, `type` = 'item_weapon',
    `instance_mode` = 'unique', `max_stack_size` = 1
WHERE `name` = 'weapon_shotgun_repeating';

-- Installation seed for the current Cattleman vertical slice.
-- Run after feather-inventory has applied its instance_mode migration.
-- Uses WHERE NOT EXISTS because older Feather schemas may not have a unique
-- index on items.name; ON DUPLICATE KEY UPDATE would create duplicate names.

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_revolver_cattleman', 'Cattleman Revolver', 'A standard single-action revolver.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_revolver_cattleman');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_revolver_schofield', 'Schofield Revolver', 'A sturdy top-break revolver.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_revolver_schofield');

-- Alpha cutover to the shared ammo_<family>_<variant> naming convention.
UPDATE `items` AS legacy
LEFT JOIN `items` AS current ON current.`name` = 'ammo_revolver_regular'
SET legacy.`name` = 'ammo_revolver_regular'
WHERE legacy.`name` = 'revolver_standard'
  AND current.`id` IS NULL;

DROP TEMPORARY TABLE IF EXISTS `feather_weapon_ammunition_seed`;
CREATE TEMPORARY TABLE `feather_weapon_ammunition_seed` (
    `name` VARCHAR(64) NOT NULL PRIMARY KEY,
    `display_name` VARCHAR(128) NOT NULL,
    `description` VARCHAR(255) NOT NULL
);

INSERT INTO `feather_weapon_ammunition_seed` (`name`, `display_name`, `description`) VALUES
    ('ammo_rifle_elephant', 'Rifle Cartridges - Nitro Express', 'Nitro Express cartridges for the Elephant Rifle.'),
    ('ammo_pistol_regular', 'Pistol Cartridges - Regular', 'Regular cartridges for pistols.'),
    ('ammo_pistol_express', 'Pistol Cartridges - Express', 'Express cartridges for pistols.'),
    ('ammo_pistol_high_velocity', 'Pistol Cartridges - High Velocity', 'High velocity cartridges for pistols.'),
    ('ammo_pistol_split_point', 'Pistol Cartridges - Split Point', 'Split point cartridges for pistols.'),
    ('ammo_pistol_explosive', 'Pistol Cartridges - Explosive', 'Explosive cartridges for pistols.'),
    ('ammo_revolver_regular', 'Revolver Cartridges - Regular', 'Regular cartridges for revolvers.'),
    ('ammo_revolver_express', 'Revolver Cartridges - Express', 'Express cartridges for revolvers.'),
    ('ammo_revolver_high_velocity', 'Revolver Cartridges - High Velocity', 'High velocity cartridges for revolvers.'),
    ('ammo_revolver_split_point', 'Revolver Cartridges - Split Point', 'Split point cartridges for revolvers.'),
    ('ammo_revolver_explosive', 'Revolver Cartridges - Explosive', 'Explosive cartridges for revolvers.'),
    ('ammo_repeater_regular', 'Repeater Cartridges - Regular', 'Regular cartridges for repeaters.'),
    ('ammo_repeater_express', 'Repeater Cartridges - Express', 'Express cartridges for repeaters.'),
    ('ammo_repeater_high_velocity', 'Repeater Cartridges - High Velocity', 'High velocity cartridges for repeaters.'),
    ('ammo_repeater_split_point', 'Repeater Cartridges - Split Point', 'Split point cartridges for repeaters.'),
    ('ammo_repeater_explosive', 'Repeater Cartridges - Explosive', 'Explosive cartridges for repeaters.'),
    ('ammo_rifle_regular', 'Rifle Cartridges - Regular', 'Regular cartridges for rifles.'),
    ('ammo_rifle_express', 'Rifle Cartridges - Express', 'Express cartridges for rifles.'),
    ('ammo_rifle_high_velocity', 'Rifle Cartridges - High Velocity', 'High velocity cartridges for rifles.'),
    ('ammo_rifle_split_point', 'Rifle Cartridges - Split Point', 'Split point cartridges for rifles.'),
    ('ammo_rifle_explosive', 'Rifle Cartridges - Explosive', 'Explosive cartridges for rifles.'),
    ('ammo_shotgun_regular', 'Shotgun - Regular', 'Regular shells for shotguns.'),
    ('ammo_shotgun_slug', 'Shotgun - Slug', 'Slug shells for shotguns.'),
    ('ammo_shotgun_buckshot_incendiary', 'Shotgun - Incendiary', 'Incendiary buckshot shells for shotguns.'),
    ('ammo_shotgun_slug_explosive', 'Shotgun - Explosive', 'Explosive slug shells for shotguns.'),
    ('ammo_varmint', 'Rifle Cartridges - Varmint', 'Regular .22 caliber cartridges for varmint rifles.'),
    ('ammo_varmint_tranquilizer', 'Rifle Cartridges - Tranquilizer', 'Tranquilizer cartridges for varmint rifles.');

UPDATE `items` AS item
INNER JOIN `feather_weapon_ammunition_seed` AS seed ON seed.`name` = item.`name`
SET item.`display_name` = seed.`display_name`,
    item.`description` = seed.`description`,
    item.`max_quantity` = 200,
    item.`max_stack_size` = 50,
    item.`weight` = 0,
    item.`usable` = 1,
    item.`category_id` = 2,
    item.`type` = 'item_ammo',
    item.`instance_mode` = 'stack';

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT seed.`name`, seed.`display_name`, seed.`description`, 200, 50, 0, 1, 2, 'item_ammo', 'stack'
FROM `feather_weapon_ammunition_seed` AS seed
WHERE NOT EXISTS (SELECT 1 FROM `items` AS item WHERE item.`name` = seed.`name`);

DROP TEMPORARY TABLE `feather_weapon_ammunition_seed`;

-- Preserve existing repair consumable stacks during the alpha item-ID cutover.
UPDATE `items` AS legacy
LEFT JOIN `items` AS current ON current.`name` = 'gun_oil'
SET legacy.`name` = 'gun_oil'
WHERE legacy.`name` = 'weapon_repair_kit'
  AND current.`id` IS NULL;

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'gun_oil', 'Gun Oil', 'Gun oil used to clean and restore weapon condition.', 20, 10, 1, 1, 8, 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'gun_oil');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cattleman_long_barrel', 'Cattleman Long Barrel', 'A long barrel made for the Cattleman Revolver.', 20, 10, 1, 0, 3, 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cattleman_long_barrel');

UPDATE `items`
SET `display_name` = 'Cattleman Revolver',
    `description` = 'A standard single-action revolver.',
    `max_quantity` = 20, `max_stack_size` = 1, `weight` = 2,
    `usable` = 1, `type` = 'item_weapon', `instance_mode` = 'unique'
WHERE `name` = 'weapon_revolver_cattleman';

UPDATE `items`
SET `display_name` = 'Schofield Revolver',
    `description` = 'A sturdy top-break revolver.',
    `max_quantity` = 20, `max_stack_size` = 1, `weight` = 2,
    `usable` = 1, `type` = 'item_weapon', `instance_mode` = 'unique'
WHERE `name` = 'weapon_revolver_schofield';

UPDATE `items`
SET `display_name` = 'Gun Oil',
    `description` = 'Gun oil used to clean and restore weapon condition.',
    `max_quantity` = 20, `max_stack_size` = 10, `weight` = 1,
    `usable` = 1, `category_id` = 8, `type` = 'item_item', `instance_mode` = 'stack'
WHERE `name` = 'gun_oil';

UPDATE `items`
SET `display_name` = 'Cattleman Long Barrel',
    `description` = 'A long barrel made for the Cattleman Revolver.',
    `max_quantity` = 20, `max_stack_size` = 10, `weight` = 1,
    `usable` = 0, `type` = 'item_item', `instance_mode` = 'stack'
WHERE `name` = 'cattleman_long_barrel';
