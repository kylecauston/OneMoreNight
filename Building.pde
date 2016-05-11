/*
  Buildings contain the map of tiles, and info on the building. Outside is considered a building (building(0)) 
 */

int tilesAcross, tilesDown;  // saves how many tiles to draw across and down

ArrayList<Building> buildings;  // all the buildings
Building current;      // building you're in

class Building {
  int ID;
  int type;
  String name;
  Tile[][] map;
  int def, maxDef;
  int[] lootTable;
  ArrayList<Zombie> zombies;
  ArrayList<Survivor> survivors;
  Furnishing[] furnishings;

  PVector spawn;
  PVector topCorner, bottomCorner;
  int rows, cols;
  String dir;
  int numClearTiles;   // this is used for figuring out how many zombies should be in a building

  String mapText;

  Building(int id, int t, String direction) {
    ID = id;
    type = t;
    dir = direction.replace("-S", "");
    maxDef = round(random(90, 110));
    def = round(random(40, 60));
    lootTable = loadLoot();
    zombies = new ArrayList<Zombie>();
    survivors = new ArrayList<Survivor>();
    furnishings = new Furnishing[6];
  }

  boolean isEmpty() {
    if (zombies.size() == 0) return true;
    return false;
  }

  void readTile() {
    this.topCorner = new PVector(100000, 100000);
    this.bottomCorner = new PVector(-100000, -100000);
    String[] numVariants = loadStrings("Maps/Map Variants.txt");  // this stores how many of each building there are
    int curVariants = int(numVariants[type]);

    if (mapText == null) mapText = this.type + this.dir + "-" + int(random(curVariants));
    String[] lines = loadStrings("Maps/map" + mapText + ".txt");
    String[] parts;

    // first, figure out the 'size' of the current map, in terms of rows/cols
    this.rows = lines.length;    // rows is just the number of lines in the file
    this.cols = 0;
    for (int i=0; i<lines.length; i++) {
      parts = split(lines[i], ",");    // split each line into it's columns
      this.cols = max(this.cols, parts.length);  // the number of columns for the map needs to be the max column size of all the rows
    }

    // then create the map
    String temp;
    this.map = new Tile[cols][rows];
    for (int r=0; r<this.rows; r++) {
      parts = split(lines[r], ",");    // split the lines up
      for (int c=0; c<this.cols; c++) {
        if (c<parts.length) {          // since the rooms aren't perfectly aligned, some spots may be greater than the string
          temp = parts[c];
        } else {          // if this is the case, treat it as a wall
          temp = "0";
        }

        switch(int(temp)) {
        case WALL:
        case FLOOR: 
          this.map[c][r] = new Base(temp, c*tSize, r*tSize, this);
          break;
        case CONT:
          this.map[c][r] = new Container(temp, c*tSize, r*tSize, this);
          break;
        case HOUSEDOOR:
          this.map[c][r] = new Door(temp, c*tSize, r*tSize, this);
          break;
        case IN_DOOR:
          this.map[c][r] = new Entrance(temp, c*tSize, r*tSize);
          break;
        case OUT_DOOR:
          this.map[c][r] = new Exit(temp, c*tSize, r*tSize, this);
          break;
        }
        if (this.map[c][r].type == OUT_DOOR) {  // this is to set the entrance spawn for a room
          this.spawn = new PVector(this.map[c][r].pos.x+tSize/2, this.map[c][r].pos.y+tSize/2);
        }
      }
    }
  }

  int[] loadLoot() {
    IntList loot = new IntList();
    String[] fullString = loadStrings("items/Text Files/locations.txt");
    String itemString = fullString[type];
    String[] parts = split(itemString, ",");

    name = parts[0];

    for (int i=1; i<parts.length; i++) {    // i = 0 is name
      if (parts[i].charAt(0) == '-') {    // if you're removing an item in the loot table
        String removing = parts[i].substring(1);
        if (loot.hasValue(nameToID(removing))) {
          for (int j=0; j<loot.size (); j++) {    // cycle through the list
            // j is spot in loot table
            int value = loot.get(j); // this gives us the item ID in the jTH slot of loot table
            if (value == nameToID(removing)) loot.remove(j);  // if the ID matches the item you're removing, remove it
          }
        }
      } else if (parts[i].equals("ALL")) {
        for (int j=0; j<items.size (); j++) {
          if (!items.get(j).isSpecial) {  // special items can't be found in chests
            loot.append(j);
          }
        }
      } else {
        loot.append(nameToID(parts[i]));
      }
    }
    return loot.array();
  }

  void fillWithZombies(int numZombies) {
    for (int i=0; i<numZombies; i++) {
      zombies.add(new Zombie(ID, zombies));
    }
  }

  void fillWithSurvivors(int numSurvivors) {
    for (int i=0; i<numSurvivors; i++) {
      survivors.add(new Civilian(ID));
    }
  }

  void takeDamage(int damage) {
    def = max(def-damage, 0);
  }

  boolean addFurnishing(Furnishing addition) {
    for (int i=0; i<furnishings.length; i++) {
      if (furnishings[i] == null) {
        furnishings[i] = addition;
        return true;
      }
    }
    return false;
  }

  void removeFurnishing(int boxnum) {
    if (you.getItem(current.furnishings[boxnum])) {
      current.furnishings[boxnum] = null;
    } else {
      console("You don't have enough room for this right now.");
    }
  }

  void showMap() {
    rectMode(CORNER);
    imageMode(CORNER);
    int col = int((you.pos.x - current.topCorner.x)/tSize);
    int row = int((you.pos.y - current.topCorner.y)/tSize);
    for (int r=row-tilesDown; r<=row+tilesDown; r++) {  // draws from where you are, to half the tiles left right up down
      for (int c=col-tilesAcross; c<=col+tilesAcross; c++) {
        if (r>=rows || r<0 || c>=cols || c<0) continue;  // if it's out of bounds
        map[c][r].display();
      }
    }
    noStroke();
  }

  void showOverview() {
    final PVector boxPos = new PVector(35, 30);
    final int boxW = 600;
    final int boxH = 500;

    pushStyle();
    rectMode(CORNER);
    stroke(#554932);
    strokeWeight(8);
    fill(#766A54);
    rect(boxPos.x, boxPos.y, boxW, boxH);
    fill(#C6B698);
    textFont(plain);
    textSize(26);
    textAlign(LEFT, TOP);
    text(name, boxPos.x+15, boxPos.y+15);
    textAlign(RIGHT, TOP);
    text("Max Def: " + maxDef, boxPos.x + boxW-15, boxPos.y+15);
    textAlign(CENTER, CENTER);
    text("Night " + (timeDay+1), boxPos.x + boxW/2, boxPos.y + 120);
    textSize(20);
    text("Zombies", boxPos.x + boxW/4, boxPos.y + 150);
    text("Defense", boxPos.x + boxW*3/4, boxPos.y + 150);
    textSize(24);
    text(minZombies + "-" + maxZombies, boxPos.x + boxW/4, boxPos.y + 175);
    text(def, boxPos.x + boxW*3/4, boxPos.y + 175);
    String warning;
    if (def < minZombies) {  // not even close
      warning = "You're gonna have a horrible night with those defenses.";
    } else if (def > maxZombies) { // super safe
      warning = "You should be fine.";
    } else { // in the middle
      warning = "You're really risking it eh? Good luck.";
    }
    if (!isEmpty()) warning = "Are you honestly gonna sleep with those zombies in here?";
    rectMode(CENTER);
    text(warning, boxPos.x + boxW/2, boxPos.y + 300, boxW - 100, boxH);
    imageMode(CENTER);
    image(sleepingBag, boxPos.x + boxW/2, boxPos.y + 420);
    fill(#766A54, 200);
    noStroke();
    if (day || !this.isEmpty()) ellipse(boxPos.x + boxW/2, boxPos.y + 420, sleepingBag.width, sleepingBag.height);
    popStyle();
  }
}

