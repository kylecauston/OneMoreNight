# One More Night

One More Night began as my first year game development project at Carleton University, 2015. Since then, it has recieved (mostly) continual work. It is written in Processing, a Java library. 

This game is a top down zombie survival game, where the player is a survivor lost in a post apocalyptic world. They need to explore, while fighting/fleeing the hordes, to find resources to help them survive. Consumables, weapons, building reinforcements, each providing very different functionality, are all integral to the player's survival. Consumables affect the player's stability, which is measured with three bars - Health, Hunger and Morale. Weapons, of course, help fight off the hordes. And building reinforcements increase the defense of a building, which is very important for when the night comes.

# Code

While doing the work throughout school, there was a lot of focus on keeping the code reusable and expandable. Examples include the Item heirarchy, text file loading and a smart tile system. After the project was done, I went back and overhauled a few major things to allow for some big additions - NPC's being one of them.

## Text files

Most of the content is loaded in through text files (all items, maps, tiles, lore etc) so that content could be very easily added. All the item types (consumable, lore, weapons, etc) have their own files and loading methods.

The maps are saved so that their strings correspond to the type of map they are (for example, the 2nd variant of a House (building type 1), entered while walking down (entrance is at the top) would have the name of map1D-2.txt, as the string is map[Building Type][direction]-[variant].txt). The tiles in the map are abstracted out to presets (combinations of solid, container and transparent booleans), and then those presets are numbered. The maps are then constructed by using the presets, with occasionally decimals (eg 4.5) where the decimal part is the variant of the tile (for tiles like grass, where there could be a few different grass tiles).

## NPC's

All entities inherit from one base class - Person. From Person you have Player and NPC. NPC splits into Zombie and Survivor, and then Survivor splits into it's own children classes. NPC's all have their own finite state machines (and can call the parent's state machine, for example a citizen might act the same as a merchant, but they're different classes for other reasons), and the states are saved as Behaviors, which dictate how an NPC moves and interacts with the environment.
