### Setup Instructions
1.Go into config.lua file and change to your framework/inventory options.
2.Add the item to your qbcore/shared/items.lua file, Your database or your ox-inventory.
3.Add the png found in the [inventory image] file to your inventory images.
4.Enjoy!

### QBCORE item:
```lua
["carjack"]= {["name"] = "carjack", ["label"] = "Car Jack",	["weight"] = 10000, 	["type"] = "item", 	["image"] = "carjack.png",	["unique"] = false, ["useable"] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "A car jack, Probably good for flipping vehicles up right."},
```

### OX-INVENTORY item:
```lua
['carjack'] = {
	label = 'Car Jack',
	weight = 10000,
    	close = true,
	stack = true,
},
```

### ESXLEGACY item:
**run this sql query:**
```sql
USE es_extended;
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES ('carjack', 'Car Jack', 5, 0, 1);
```
