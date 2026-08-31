-- Installation seed for the current Cattleman vertical slice.
-- Run after feather-inventory has applied its instance_mode migration.
-- Uses WHERE NOT EXISTS because older Feather schemas may not have a unique
-- index on items.name; ON DUPLICATE KEY UPDATE would create duplicate names.

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cattleman_revolver', 'Cattleman Revolver', 'A standard single-action revolver.', 20, 1, 2, 1, 3, 'item_weapon', 'unique'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cattleman_revolver');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'revolver_standard', 'Revolver Ammunition', 'Standard ammunition for revolvers.', 200, 50, 0, 1, 2, 'item_ammo', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'revolver_standard');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'weapon_repair_kit', 'Weapon Repair Kit', 'Materials used to repair a damaged weapon.', 20, 10, 1, 1, 8, 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'weapon_repair_kit');

INSERT INTO `items`
    (`name`, `display_name`, `description`, `max_quantity`, `max_stack_size`, `weight`, `usable`, `category_id`, `type`, `instance_mode`)
SELECT 'cattleman_long_barrel', 'Cattleman Long Barrel', 'A long barrel made for the Cattleman Revolver.', 20, 10, 1, 0, 3, 'item_item', 'stack'
WHERE NOT EXISTS (SELECT 1 FROM `items` WHERE `name` = 'cattleman_long_barrel');

UPDATE `items`
SET `display_name` = 'Cattleman Revolver',
    `description` = 'A standard single-action revolver.',
    `max_quantity` = 20, `max_stack_size` = 1, `weight` = 2,
    `usable` = 1, `type` = 'item_weapon', `instance_mode` = 'unique'
WHERE `name` = 'cattleman_revolver';

-- One-time normalization for weapons issued before the configured weapon ID
-- was aligned with the inventory item name. Idempotent: only the old value is
-- rewritten, and revisions advance so stale compare-and-set writes conflict.
UPDATE `inventory_items` ii
INNER JOIN `items` i ON i.`id` = ii.`item_id`
SET ii.`metadata` = JSON_SET(ii.`metadata`, '$.weaponDefinitionId', 'cattleman_revolver'),
    ii.`metadata_revision` = ii.`metadata_revision` + 1,
    ii.`row_revision` = ii.`row_revision` + 1
WHERE i.`name` = 'cattleman_revolver'
  AND JSON_VALID(ii.`metadata`)
  AND JSON_UNQUOTE(JSON_EXTRACT(ii.`metadata`, '$.weaponDefinitionId')) = 'revolver_cattleman';
UPDATE `items`
SET `display_name` = 'Revolver Ammunition',
    `description` = 'Standard ammunition for revolvers.',
    `max_quantity` = 200, `max_stack_size` = 50, `weight` = 0,
    `usable` = 1, `category_id` = 2, `type` = 'item_ammo', `instance_mode` = 'stack'
WHERE `name` = 'revolver_standard';

UPDATE `items`
SET `display_name` = 'Weapon Repair Kit',
    `description` = 'Materials used to repair a damaged weapon.',
    `max_quantity` = 20, `max_stack_size` = 10, `weight` = 1,
    `usable` = 1, `category_id` = 8, `type` = 'item_item', `instance_mode` = 'stack'
WHERE `name` = 'weapon_repair_kit';

UPDATE `items`
SET `display_name` = 'Cattleman Long Barrel',
    `description` = 'A long barrel made for the Cattleman Revolver.',
    `max_quantity` = 20, `max_stack_size` = 10, `weight` = 1,
    `usable` = 0, `type` = 'item_item', `instance_mode` = 'stack'
WHERE `name` = 'cattleman_long_barrel';
