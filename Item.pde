
ArrayList<Item> items;

// this is a variable used once. 
// it is to deal with whether or not to remove the music player
// from the inventory when it is used. Since it relies on 
// selectInput's callback function, we can't remove the music player
// until user has picked input. This is problematic and this is the
// only solution I can think of, due to selectInput's limited callback
// functionality. So yay global variables
boolean usedMusicPlayer = false; 

abstract class Item implements Cloneable {
  int ID;
  String name;
  PImage pic;
  boolean isSpecial;
  int ran = -1;

  Item (String Name) {
    ID = items.size();
    isSpecial = false; 
    name = Name;
    if (this instanceof Harvest) {
      pic = loadImage("Items/" + name + "_0.png");
    } else {
      pic = loadImage("Items/" + name + ".png");
    }
  }

  public Item clone() {
    try {
      return (Item)super.clone();
    } 
    catch(Exception e) {
      return null;
    }
  }

  int getReturnItem() {
    return -1;
  }

  abstract boolean use(Player user);    // returns false if not used
}

abstract class Weapon extends Item {
  int damage, range, cooldownTime, knockback;
  boolean isLoud, isRanged;
  int kills = 0;

  Weapon(String[] fromText) {
    super(fromText[0]);
    damage = int(fromText[1]);
    range = int(fromText[2]);
    cooldownTime = int(float(fromText[3])*1000);
    knockback = int(fromText[4]);
    isLoud = bool(fromText[5]);
    isRanged = bool(fromText[6]);
  }

  boolean use(Player user) {
    Item temp = user.equippedWeapon;    // keep track of previous weapon
    user.equippedWeapon = this;  // give user this weapon
    if (temp != null) user.getItem(temp);   // if user had a weapon, give it back
    console(name + connectingWord(name) + "equipped.");
    return true;  // can always equip a weapon
  }

  abstract Person[] whatHit(PVector target, Person user);    // write how the weapon functions
  abstract void debugDisplay();
}

class Straight extends Weapon {
  // straight line single shot  
  Straight(String[] fromText) {
    super(subset(fromText, 0, fromText.length - 1));
  }

  boolean use(Player user) {
    return(super.use(user));
  }

  Person[] whatHit(PVector target, Person user) {
    Person[] allHit = hitOnLine(user.pos, target, user.getRange(), user);
    if (allHit.length > 0) {
      return (Person[])subset(allHit, 0, 1);
    } else {
      return (Person[])subset(allHit, 0, 0);
    }
  }

  void debugDisplay() {
    pushStyle();
    noFill();
    stroke(#FFFFFF);
    PVector toTarg = mouse.get();
    toTarg.sub(you.pos);
    if (toTarg.mag() > range) toTarg.setMag(range);
    line(you.pos.x, you.pos.y, you.pos.x+toTarg.x, you.pos.y+toTarg.y);
    //ellipse(you.pos.x, you.pos.y, range*2, range*2);
    popStyle();
  }
}

class Throwable extends Weapon {
  int radius;   // radius of weapon when hit

  Throwable(String[] fromText) {
    super(subset(fromText, 0, fromText.length - 2));
    radius = int(fromText[8]);
  }

  boolean use(Player user) {
    return(super.use(user));
  }

  PVector explosionLocation(PVector target, Person user) {
    PVector toTarget = new PVector(target.x - user.pos.x, target.y - user.pos.y);
    if (toTarget.mag() > user.getRange()) toTarget.setMag(user.getRange());
    PVector explosionSpot = new PVector(user.pos.x+toTarget.x, user.pos.y+toTarget.y);
    return explosionSpot;
  }

  Person[] whatHit(PVector target, Person user) {
    ArrayList<Person> entities = allEntities();

    ArrayList<Person> hit = new ArrayList<Person>();

    // figure out where the throwable lands
    PVector explosionSpot = explosionLocation(target, user);

    Person temp;
    for (int i=0; i<entities.size (); i++) {
      temp = entities.get(i);
      if (temp == user) continue;
      if (temp.pos.dist(explosionSpot) < radius) hit.add(temp);
    }

    Person[] array = new Person[hit.size()];
    for (int i=0; i<array.length; i++) array[i] = hit.get(i);
    return array;
  }

  void debugDisplay() {
    pushStyle();
    noFill();
    stroke(#FFFFFF);
    PVector hitZone = explosionLocation(mouse, you);
    ellipse(hitZone.x, hitZone.y, radius*2, radius*2);
    popStyle();
  }
}

class Spread extends Weapon {
  float angle;   // the spread of the weapon's shot

  Spread(String[] fromText) {
    super(subset(fromText, 0, fromText.length - 2));
    angle = radians(float(fromText[8]));
  }

  boolean use(Player user) {
    return(super.use(user));
  }

  Person[] whatHit(PVector target, Person user) {

    ArrayList<Person> entities = allEntities();

    ArrayList<Person> hit = new ArrayList<Person>();

    PVector toTarget = new PVector(target.x-user.pos.x, target.y-user.pos.y);

    Person temp;
    PVector toTemp = new PVector();
    for (int i=0; i<entities.size (); i++) {
      temp = entities.get(i);
      if (temp == user) continue;  // user can't be hit by shotgun
      toTemp.set(temp.pos.x - user.pos.x, temp.pos.y - user.pos.y);
      if (temp.pos.dist(user.pos) < user.getRange() && PVector.angleBetween(toTarget, toTemp) < angle/2 && hasVisibilityLine(user.pos, temp.pos)) {    // if it's in the cone of hit
        hit.add(temp);
      }
    }

    Person[] hitArray = new Person[hit.size()];
    for (int i=0; i<hitArray.length; i++) hitArray[i] = hit.get(i);

    return hitArray;
  }

  void debugDisplay() {
    pushStyle();
    noFill();
    stroke(#FFFFFF);
    PVector toMouse = mouse.get();
    toMouse.sub(you.pos);
    float direction = toMouse.heading();
    arc(you.pos.x, you.pos.y, range*2, range*2, direction-angle/2, direction+angle/2, PIE); 
    popStyle();
  }
}

class Consumable extends Item {
  LootTable<Integer[]> effects_table;
  String action;
  LootTable<Integer> returnItem_table;

  Consumable(String[] fromText) {
    super(fromText[0]);

    // make an "empty" table by having a 100% chance to get -1 (no item)
    float[] chance = new float[1];
    Integer[] outcome = new Integer[1];
    chance[0] = 1.0;
    outcome[0] = ID;    
    returnItem_table = new LootTable<Integer>(chance, outcome);

    File randomEffect = dataFile("Items/Text Files/Tables/effects_" + name + ".txt");
    if (randomEffect.exists()) {
      // format: health effect, hunger effect, morale effect, chance
      String[] lines = loadStrings("Items/Text Files/Tables/effects_" + name + ".txt");

      float[] chances = new float[lines.length];
      Integer[][] outcomes = new Integer[lines.length][3];

      String[] parts;
      for (int i=0; i<lines.length; i++) {
        parts = split(lines[i], ",");
        for (int j=0; j<3; j++) outcomes[i][j] = int(parts[j]);
        chances[i] = float(parts[3]);
      }

      effects_table = new LootTable<Integer[]>(chances, outcomes);
    } else {
      float[] certain = new float[1];
      Integer[][] effect = new Integer[1][3];
      certain[0] = 1.0;

      effect[0][0] = int(fromText[1]);
      effect[0][1] = int(fromText[2]);
      effect[0][2] = int(fromText[3]);

      effects_table = new LootTable<Integer[]>(certain, effect);
    }
    action = fromText[4];
  }

  void setReturnItems() {
    // must be called after all items have been generated, or else the return items may not exist
    File returnItem = dataFile("Items/Text Files/Tables/return_" + name + ".txt");
    if (returnItem.exists()) {   // then it has a return item table, load loot table
      String[] lines = loadStrings("Items/Text Files/Tables/return_" + name + ".txt");

      float[] chances = new float[lines.length];  // first line in .txt is formatting
      Integer[] outcomes = new Integer[lines.length];

      String[] parts;
      for (int i=0; i<lines.length; i++) {
        parts = split(lines[i], ",");
        outcomes[i] = nameToID(parts[0]);
        if (outcomes[i] == -1) println(name + ": Return item " + parts[0] + " doesn't exist.");
        chances[i] = float(parts[1]);
      }
      returnItem_table = new LootTable<Integer>(chances, outcomes);
    } else {
      float[] chance = new float[1];
      Integer[] out = new Integer[1];
      chance[0] = 1;
      out[0] = -1;
      returnItem_table = new LootTable<Integer>(chance, out);
    }
  }

  boolean use(Player user) {
    if (ID == nameToID("Music Player")) {
      selectInput("Pick a song!", "fileSelected");
      prevstate=state;
      state = pausetest;
      theme.pause();
      return false;
    } else {
      Integer[] effect = effects_table.generate();
      user.health = constrain(user.health + effect[0], 1, user.maxHealth);
      user.hunger = constrain(user.hunger + effect[1], 1, user.maxHunger);
      user.morale = constrain(user.morale + effect[2], 1, user.maxMorale);
      console(name + connectingWord(name) + action + ".");
      itemsUsed++;
      return true;  // can always use consumables
    }
  }

  int getReturnItem() {
    return returnItem_table.generate();
  }
}

class Material extends Item {

  Material(String fromText) {
    super(fromText);
  }

  boolean use(Player user) {
    return false;   // can't "use" materials
  }
}

abstract class BuildingUpgrade extends Item {
  BuildingUpgrade(String fromText) {
    super(fromText);
  }

  boolean use(Player user) {
    if (current.ID != 0) {      // can't reinforce outside
      if (!current.isEmpty()) {  // or in zombie filled buildings
        console("\"I should probably clear out this building first...\"");
        return false;
      }
    } else {  // if it's outside
      console("OAK: " + user.name + "! This isn't the time to use that!");
      return false;
    }
    return true;
  }
}

class Reinforcement extends BuildingUpgrade {
  int defEffect, maxEffect;

  Reinforcement(String[] fromText) {
    super(fromText[0]);
    defEffect = int(fromText[1]);
    maxEffect = int(fromText[2]);
  }

  boolean use(Player user) {
    if (super.use(user)) {
      if (current.def < current.maxDef) {  // if there's room to upgrade
        current.maxDef += maxEffect;
        current.def = constrain(current.def+defEffect, 0, current.maxDef);
        console(name + connectingWord(name) + "used to upgrade the building.");
        return true;
      } else {   // trying to upgrade beyond max
        console("The " + name + " won't have any effect. Upgrade the foundation instead.");
        return false;
      }
    } else {
      return false;
    }
  }
}

abstract class Furnishing extends BuildingUpgrade {
  /* Resume 
   - need to prevent people from using item more than once
   -> can't use the current style of just setting a boolean
   because all items share the same Item object. So 
   setting an Item to 'used' will either trigger every
   instance of the Item at night, or will prevent use
   of any other instance of that Item.
   -> only thought right now is to overhaul items into 
   individual copies opposed to having a main parent  
   
   */
  boolean interactedWith = false;

  Furnishing(String name) {
    super(name);
  }

  boolean use(Player user) {
    // places the item in building
    if (super.use(user)) {
      if (current.addFurnishing(this)) {
        console("You put the " + name.toLowerCase() + " in the building.");
        return true;
      }
    } 
    return false;
  }

  boolean interact() { // edit!
    if (!interactedWith) {
      interactedWith = true;
      return true;
    } else {
      console("You've already interacted with the " + name.toLowerCase() + " today.");
      return false;
    }
  }

  abstract String getAction();
  abstract PImage getImage();
}

class Radio extends Furnishing {
  final String action = "Tune";

  Radio() {
    super("Radio");
  }

  String getAction() {
    return action;
  }

  PImage getImage() {
    return pic;
  }

  boolean interact() {
    if (super.interact()) { 
      console("You only hear the haunting sound of static.");
      return true;
    }
    return false;
  }
}

class Harvest extends Furnishing {
  int produces; // the ID of the item that is harvested
  int daysToMature; // how long the item takes to mature
  int age = 0; // days interacted with
  PImage[] icons; // pictures of item as it matures
  String[] actions; // action each days (eg plant, water, trim, water, last is harvest)
  // int[] requires;  // the items that are required at each day, usually nothing

  Harvest(String[] fromText) {
    super(fromText[0]); // name
    produces = nameToID(fromText[1]);
    if (produces == -1) {
      println("Error! " + name + " does not have a valid harvest item.");
      produces = 0;
    }
    daysToMature = int(fromText[2]);
    icons = new PImage[daysToMature+1]; // all stages + harvest ready pic
    actions = new String[daysToMature]; 

    // load the images
    PImage last = null;
    File temp;
    // go through each age step, and try to add a picture
    // if the picture doesn't exist - add the last picture that existed
    for (int i=0; i<daysToMature; i++) {
      temp = dataFile("Items/" + name + "_" + i + ".png");
      if (temp.exists()) {
        last = loadImage("Items/" + name + "_" + i + ".png");
      } 
      icons[i] = last;

      // also load the actions at the same time
      actions[i] = fromText[3+i];
    }

    icons[daysToMature] = loadImage("Items/" + name + "_" + daysToMature + ".png");
  }

  String getAction() {
    return (age < daysToMature) ? actions[age] : "Harvest";
  }

  PImage getImage() {
    return icons[age];
  }

  boolean interact() {
    if (super.interact()) {
      if (age == daysToMature) { // if it's ready to harvest
        if (you.getItem(produces)) { // and you have room in your inventory
          // set the item back beginning
          age = 0;
          console("You harvest " + items.get(produces).name.toLowerCase() + " from the " + name + ".");
          return true;
        } else {
          console("You don't have room to harvest this right now.");
          return false;
        }
      } else {
        console("You " + actions[age].toLowerCase() + " the " + name.toLowerCase() + ".");
        return true;
      }
    } 

    return false;
  }
}

void loadItems() {
  // loads each of the item text files

    // load consumables
  String[] itemText = loadStrings("Items/Text Files/consumables.txt");
  for (int i=1; i<itemText.length; i++) items.add((Item)(new Consumable(split(itemText[i], ","))));  

  // load weapons
  itemText = loadStrings("Items/Text Files/weapons.txt");
  String[] parts;
  int weaponType;
  for (int i=1; i<itemText.length; i++) {
    parts = split(itemText[i], ",");
    weaponType = int(parts[7]);
    if (weaponType == 0) {    // straight
      items.add((Item)(new Straight(parts)));
    } else if (weaponType == 1) {  // spread
      items.add((Item)(new Spread(parts)));
    } else if (weaponType == 2) {  // throwable
      items.add((Item)(new Throwable(parts)));
    }
  }

  // load materials
  itemText = loadStrings("Items/Text Files/materials.txt");
  for (int i=1; i<itemText.length; i++) items.add((Item)(new Material(itemText[i])));  

  // load building upgrades ~ ~ ~

  // load building reinforcements
  itemText = loadStrings("Items/Text Files/reinforcements.txt");
  for (int i=1; i<itemText.length; i++) items.add((Item)(new Reinforcement(split(itemText[i], ","))));

  // load furnishings ~ ~ ~

  // load uniques
  items.add((Item)(new Radio()));

  // load harvestables
  itemText = loadStrings("Items/Text Files/harvestables.txt");
  for (int i=1; i<itemText.length; i++) items.add((Item)(new Harvest(split(itemText[i], ","))));

  // set up return items
  Item temp;
  for (int i=0; i<items.size (); i++) {
    temp = items.get(i);
    if (temp instanceof Consumable) ((Consumable)temp).setReturnItems();
  }

  makeSpecials();
}

void makeSpecials() {
  // takes the specials text and makes the listed items special
  String[] specials = loadStrings("Items/Text Files/specials.txt");
  for (String name : specials) items.get(nameToID(name)).isSpecial = true;
}

Item findFavWeapon() {
  int curHighest = 0;
  Item favWeapon = null;
  Item temp;
  for (int i=0; i<items.size (); i++) {
    temp = items.get(i);
    if (temp instanceof Weapon && ((Weapon)temp).kills > curHighest) {
      curHighest = ((Weapon)temp).kills;
      favWeapon = temp;
    }
  }
  return favWeapon;
}

