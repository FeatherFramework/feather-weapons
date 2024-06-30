/*This is a temp sql for development, will be moved to recipe when script is released*/
INSERT INTO categories (name) VALUES ("weapons");

INSERT INTO items (name, display_name, description, max_quantity, max_stack_size, weight, usable, category_id, type) VALUES ("knife", 'Knife', "A knife", 1, 1, 1, 1, 4, "item_item");
INSERT INTO items (name, display_name, description, max_quantity, max_stack_size, weight, usable, category_id, type) VALUES ("volcanic_pistol", 'Volcanic Pistol', "A Volcanic Pistol", 1, 1, 1, 1, 4, "item_item");