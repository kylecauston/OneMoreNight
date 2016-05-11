
/*
  Tiles make up the map.
 
 - heirarchize tiles?
 */

final int tSize = 50;

abstract class GridTile {
  // class used in grid math static class
  PVector pos;
  boolean solid, tagged;
  int size;

  GridTile(float x, float y, float tileSize) {
    pos = new PVector(x, y);
    solid = false;
    tagged = false;
    size = int(tileSize);
  }

  PVector getCenter() {
    return new PVector(pos.x + size/2, pos.y + size/2);
  }
}

abstract class Tile extends GridTile {
  int type;      // which preset tile this is represented by, mostly used for image
  int variant;   // picture variation (eg floor could have 1 carpet, 2 hardwoord, 3 tile, etc). for doors, denotes which building type to go to
  boolean transparent;   //  LoS/shooting, search for containers, and opened for IN_DOOR types
  int loot;      // what is in container
  Building build;
  boolean safe;
  String mapText;

  Tile (String fromMap, float x, float y, Building build) { 
    super(x, y, tSize);
    pos = new PVector(x, y);

    mapText = fromMap;

    safe = false;
    if (fromMap.indexOf("-s") != -1 && !solid) {
      safe = true;  // if there is a "-s", it is denoted safe
      fromMap = fromMap.substring(0, fromMap.indexOf("-s"));
    }

    String[] apart = split(fromMap, ".");
    type = int(apart[0]);
    if (apart.length == 3) {  // if the map has three pieces, it's a door
      variant = int(apart[1]);
      //dir = apart[2].toUpperCase();  // the maps are saved with capitals, this is just to ensure it is capital
    } else if (apart.length == 2) {  // if the map part has two pieces, the second number is the variant
      variant = int(apart[1]);
    } else {    // if not, variant is just 0;
      variant = 0;
    }

    this.build = build;

    // uses the presets to assign values to the tile
    solid = tileType[type].solid;
    transparent = tileType[type].transparent;

    // update the maps attributes
    current.topCorner.x = min(pos.x, current.topCorner.x);
    current.topCorner.y = min(pos.y, current.topCorner.y);
    current.bottomCorner.x = max(pos.x+tSize, current.bottomCorner.x);
    current.bottomCorner.y = max(pos.y+tSize, current.bottomCorner.y);
    if (!solid) current.numClearTiles++;
  }

  abstract boolean interact(Player user);
  abstract void display();
}

class Base extends Tile {
  Base(String fromText, float x, float y, Building build) {
    super(fromText, x, y, build);
  }

  boolean interact(Player user) {
    // empty
    return false;
  }

  void display() {
    PImage pic = tileMap.get(str(build.type) + str(type) + str(variant));
    image(pic, pos.x+TRANS.x, pos.y+TRANS.y, tSize, tSize);
  }
}

class Door extends Tile {
  Door(String fromText, float x, float y, Building build) {
    super(fromText, x, y, build);
  }

  boolean interact(Player user) {
    int c = int((user.pos.x - current.topCorner.x)/tSize);
    int r = int((user.pos.y - current.topCorner.y)/tSize);
    if (current.map[c][r] != this) { // if the user is IN the door
      solid = !solid;
      transparent = !transparent;
      console("You interact with the door.");
      return true;
    }
    return false;
  }

  void display() {
    fill(#1816ED);
    rect(pos.x+TRANS.x, pos.y+TRANS.y, tSize, tSize);
  }
}

class Entrance extends Tile {
  boolean opened;
  String dir;

  Entrance(String fromText, float x, float y) {
    super(fromText, x, y, buildings.get(0));  // in doors are only outside
    String[] apart = split(fromText, ".");
    dir = apart[2].toUpperCase();
    opened = false;
  } 

  boolean interact(Player user) {
    int c = int((user.pos.x - current.topCorner.x)/tSize);
    int r = int((user.pos.y - current.topCorner.y)/tSize);
    if (current.map[c][r] == this) {
      // checks if the door has been entered before, if not
      // then generate a new building with the variant. if 
      // it has, then go to the variant.
      if (!opened) {
        opened = true;  // door has been opened  
        int newID = buildings.size();
        buildings.add(new Building(newID, variant, dir));  // add a new building
        variant = (buildings.size()-1);   // now set the door to point to the new building
        current = buildings.get(buildings.size()-1);  
        current.readTile();
        int numZombies = round(current.numClearTiles * (0.2 + random(-0.05, 0.05)));
        if (safe) {
          current.fillWithSurvivors(int(numZombies/3));
        } else {
          current.fillWithZombies(numZombies);
        }
        buildingsEntered++;
      } else {
        current = buildings.get(variant);  // set the current building to the new one
      }
      user.whichBuilding = current.ID;
      user.outsidePos.set(user.pos);  // save your outside coords
      user.pos.set(current.spawn); // set yourself inside the door of the building
      areaFade = 500;
      return true;
    }
    return false;
  }

  void display() {
    fill(#1816ED);
    rect(pos.x+TRANS.x, pos.y+TRANS.y, tSize, tSize);
  }
}

class Exit extends Tile {
  Exit(String fromText, float x, float y, Building build) {
    super(fromText, x, y, build);
  }

  boolean interact(Player user) {
    int c = int((user.pos.x - current.topCorner.x)/tSize);
    int r = int((user.pos.y - current.topCorner.y)/tSize);
    if (current.map[c][r] == this) {
      current = buildings.get(0);
      user.pos.set(user.outsidePos);
      user.whichBuilding = 0;
      state = playtest;
      areaFade = 500;
      return true;
    }
    return false;
  }

  void display() {
    fill(#1816ED);
    rect(pos.x+TRANS.x, pos.y+TRANS.y, tSize, tSize);
  }
}

class Container extends Tile {
  int loot;

  Container(String fromText, float x, float y, Building build) {
    super(fromText, x, y, build);
    loot = build.lootTable[int(random(build.lootTable.length))];
  }

  boolean interact(Player user) {
    if (loot != -1) {
      Item item = items.get(this.loot);
      String lootName;

      if (item == lore) {
        if (journal.getSize() <= storyline.length) {
          lootName = loreNames[journal.getSize()-1].toLowerCase();
          lootName = indefiniteArticle(lootName) + lootName;
          console("You search the container and find " + lootName + ". It was added to your journal.");
          you.getItem(loot);
          loot = -1;
          return true;
        } else {
          while (item == lore) {
            loot = build.lootTable[int(random(build.lootTable.length))];
            item = items.get(loot);
          }
        }
      }


      lootName = item.name.toLowerCase();

      lootName = indefiniteArticle(lootName) + lootName;

      if (user.getItem(loot)) {
        loot = -1;
        console("You search the container and find " + lootName + ".");
        itemsFound++;
      } else {
        console("You find " + lootName + " in the container, but don't have any room.");
      }
    } else {
      console("The container is empty.");
    }
    return true;
  }

  void display() {
    PImage pic = tileMap.get(str(build.type) + str(type) + str(variant));
    image(pic, pos.x+TRANS.x, pos.y+TRANS.y, tSize, tSize);
  }
}

Tile checkNearby(int searchType, PVector location, boolean middle, boolean surrounding) {
  // checks the adjecent tiles for the specified search type
  int col = int((location.x - current.topCorner.x)/tSize);
  int row = int((location.y - current.topCorner.y)/tSize);

  int foundR = -1;
  int foundC = -1;

  for (int r=row-1; r<=row+1; r++) {
    for (int c=col-1; c<=col+1; c++) {
      if (r<0||c<0||c>current.cols||r>current.rows) continue; //conditions in which tile is invalid
      if (!middle && (r==row && c==col)) continue;  // only if you're skipping the middle
      if (!surrounding && (r != row && c != col)) continue;   // if you're only checking the inside tile, skip the rest
      if (current.map[c][r].type == searchType) {
        if (foundR == -1 && foundC == -1) {  // if this is the first or only tile of it's type
          foundR = r;
          foundC = c;
        } else {  // this implies there's more than one of the selected type
          // need to pick the closest one
          float toFirst = dist(current.map[foundC][foundR].pos.x+tSize/2, current.map[foundC][foundR].pos.y+tSize/2, you.pos.x, you.pos.y);
          float toCurr = dist(current.map[c][r].pos.x+tSize/2, current.map[c][r].pos.y+tSize/2, you.pos.x, you.pos.y);
          if (toCurr < toFirst) { // if the new one is closer, and searchable
            foundR = r;
            foundC = c;
          }
        }
      }
    }
  }
  if (foundR > 0 && foundC > 0) {    // if you found a tile, return it
    return current.map[foundC][foundR];
  } else {
    return null;
  }
}

void interact(Player user) { 
  Tile[] nearby = new Tile[5]; // center tile + four surrounding tiles

  int c = int((user.pos.x - current.topCorner.x)/tSize);
  int r = int((user.pos.y - current.topCorner.y)/tSize);

  nearby[0] = current.map[c][r];
  nearby[1] = current.map[c+1][r];
  nearby[2] = current.map[c-1][r];
  nearby[3] = current.map[c][r+1];
  nearby[4] = current.map[c][r-1];

  Tile[] orderedTiles = orderOfCloseness(nearby, user.pos);

  for (int i=0; i<orderedTiles.length; i++) {
    if (orderedTiles[i].interact(user)) break;
  }
}

