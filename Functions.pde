
boolean bool(String arg) {
  // used to take input from .txt file and turn into boolean
  if (arg.equals("t") || arg.equals("T") || arg.equals("1")) return true;
  return false;
}

int nameToID(String item) {
  // takes an item name and returns the ID, or -1 if not found
  Item temp;
  for (int i=0; i<items.size (); i++) {
    temp = items.get(i);
    if (temp.name.equals(item)) return i;
  }
  return -1;
}

boolean isVowel(char let) {
  // self explanitory
  switch (let) {
  case 'a':
  case 'e':
  case 'i':
  case 'o': 
  case 'u':
    return true;
  }
  return false;
}

boolean isMultiple(String noun) {
  // takes a noun, and returns whether or not it is a 'multiple' (eg trees vs tree)
  if (noun.charAt(noun.length()-1) == 's') return true;
  return false;
}

String indefiniteArticle(String word) {
  // takes a noun and gives the proper indefinite article
  String article = "";
  if (!isMultiple(word)) {  // is single item
    article += "a";
    if (isVowel(word.charAt(0))) article += "n";
    article += " ";
  }
  return article;
}

String connectingWord(String word) {
  // takes a noun and gives the proper: were/was
  String connectingWord = " was ";
  if (isMultiple(word)) connectingWord = " were ";  // if it's multiple
  return connectingWord;
}

String correctFilePath(String path) {
  // takes a computer generated file path and converts into processing file path
  // why this is necessary isn't exactly known
  String corrected = "";
  for (int i=0; i<path.length (); i++) {
    if (path.charAt(i) == '\\') {    // if it finds a backslash (only one, double is to use \ in char)
      corrected+='/';
    } else {
      corrected+=path.charAt(i);
    }
  }
  return corrected;
}

void line(PVector start, PVector finish) {
  // draws a line between start and finish, just for ease
  line(start.x, start.y, finish.x, finish.y);
}

void rect(PVector c1, PVector c2) {
  // draws a rectangle with c1 and c2 as corners, for ease
  pushStyle();
  rectMode(CORNERS);
  rect(c1.x, c1.y, c2.x, c2.y);
  popStyle();
}

void ellipse(PVector c, int rad) {
  // draws ellipse at c with radius rad, for ease
  ellipse(c.x, c.y, rad, rad);
}

int randint(int low, int high) {
  // returns a random integer between low and high
  return(int(random(low, high)));
}

int randint(int high) {
  // returns a random integer between 0 and high
  return(randint(0, high));
}

void fileSelected(File selected) {
  // used to play a song selected with file explorer
  if (selected != null) {
    String path = correctFilePath(selected.getAbsolutePath());
    
    if (path.substring(path.length()-4, path.length()).equals(".mp3")) {  // only play songs
      song = minim.loadFile(path);
      song.play();
      song.setGain(-15);
      usedMusicPlayer = true;
      console("This is a good song!");
      itemsUsed++;
    } else {
      console("I guess I'll listen to it later.");
    }
  } else {
    console("I guess I'll listen to it later.");
  }

  state = playtest;
}

int cycleUp(int current, int arraySize) {
  // takes the current number and the max, adds one and if it's higher than max, it sets to 0
  int number; 
  number = (current+1) % arraySize;
  return number;
}

int cycleDown(int current, int arraySize) {
  // takes current number and max, subtracts one and if it's lower than 0, set to max
  int number;
  if (current <= 0) {
    number = arraySize-1;
  } else {
    number = current-1;
  }
  return number;
}

void loadTime(String whatLoading) {
  // just prints out time since last time = millis(), with some string to make it nicer
  // sets time to current time, so many loadTime calls can be made in succession
  float delta = millis() - time;
  float average = oldLoadTimeAverage.get(whatLoading);
  String symbol = (average > delta) ? "-" : "+";
  println(whatLoading + " took " + nf(delta, 0, 0) + "ms to load. (" + symbol + (nf(abs(average-delta), 0, 0)) + "ms)");
  //loadAverages_file.print(whatLoading + ":" + delta + " ");
  newLoadTimeTotals_map.put(whatLoading, delta);
  time = millis();
}

void writeAverages() {
  // takes the loaded TimeTotals map, adds it to the total averages
  // then writes out the new averages
  // load the averages file, and split it by commas
  String[] oldAverages = split(loadStrings("data/LoadTimes.txt")[0], ",");
  float numValuesComputed = float(oldAverages[0]);

  // now we have an array of LoadingType:time, where the first array value is how many values
  // have been used to compute the current averages (since they're all the same amount)
  float newTotal;
  String[] parts;
  for (int i=1; i<oldAverages.length; i++) {
    parts = split(oldAverages[i], ":");
    newTotal = float(parts[1]) * numValuesComputed;
    newTotal += newLoadTimeTotals_map.get(parts[0]);
    newLoadTimeTotals_map.put(parts[0], newTotal);
  }

  // make pairs of LoadName:newAverage
  numValuesComputed++;
  String name;
  String[] chunks = new String[oldAverages.length]; // room for each value + numComputations
  chunks[0] = str(numValuesComputed);
  for (int i=1; i<chunks.length; i++) {
    // we use old averages array just for the names
    name = split(oldAverages[i], ":")[0];
    chunks[i] = (name + ":" + (newLoadTimeTotals_map.get(name)/numValuesComputed));
  }

  // should have an array of paired values now

  // so join them,
  String output = join(chunks, ",");

  PrintWriter file = createWriter("data/LoadTimes.txt");

  // print them and close file
  file.print(output);
  file.flush();
  file.close();
}

ArrayList<Person> allEntities() {
  // returns an arraylist of every entity: all zombies, all survivors (outdoor), 
  //   all citizens of the nearest safehouse and then the player
  ArrayList<Person> list = new ArrayList<Person>();
  list.addAll(current.zombies);
  list.addAll(current.survivors);
  list.addAll(closestSafezone(you).survivors);
  list.add(you);
  return list;
}

ArrayList<Person> allHostiles(Person seeker) {
  // returns all Person's that are considered hostile to Person seeker
  ArrayList<Person> entities = new ArrayList<Person>();

  if (seeker instanceof Player || seeker instanceof Survivor) entities.addAll(current.zombies);
  if (seeker instanceof Zombie) {
    entities.add(you);
    entities.addAll(current.survivors);
    entities.addAll(closestSafezone(seeker).survivors);
  }

  return entities;
}

Person closestEnemy(Person seeker) {
  // returns the closest enemy to seeker
  float distance = 10000;
  Person closest = null;

  ArrayList<Person> enemies = allHostiles(seeker);

  Person temp;
  for (int i=0; i<enemies.size (); i++) {
    temp = enemies.get(i);
    if (seeker.pos.dist(temp.pos) < distance) {
      distance = seeker.pos.dist(temp.pos);
      closest = temp;
    }
  }
  return closest;
}

Safezone closestSafezone(Person seeker) {
  // returns the closest safezone to the seeker
  // ADD call this function less, maybe every 100 ticks?
  float distance = -1;
  Safezone closest = null;
  for (Safezone zone : safezones) {
    if (distance == -1 || seeker.pos.dist(zone.centerpoint) < distance) {
      distance = seeker.pos.dist(zone.centerpoint);
      closest = zone;
    }
  }
  return closest;
}

Tile[] orderOfCloseness(Tile[] allTiles, PVector centerpoint) {
  // given a list of tiles, lists them in the order or distance from user
  ArrayList<Tile> tileList = new ArrayList<Tile>();
  for (int i=0; i<allTiles.length; i++) tileList.add(allTiles[i]);
  Tile[] closenessArray = new Tile[allTiles.length];

  Tile temp;
  // loop through all the tiles
  for (int c=0; c<allTiles.length; c++) {
    // now loop through all the remaining nodes and find the closest
    Tile closest = null;
    float distance = 10000;
    for (int i=0; i<tileList.size (); i++) {
      temp = tileList.get(i);
      if (closest == null || centerpoint.dist(temp.getCenter()) < distance) {
        closest = temp;
        distance = centerpoint.dist(temp.getCenter());
      }
    }
    // now add the closest tile to the array, then remove it from the list of remaining tiles
    closenessArray[c] = closest;
    tileList.remove(closest);
  }
  return closenessArray;
}

Person[] hitOnLine(PVector pos, PVector target, int range, Person seeker) {
  // makes a straight line from pos to target, and returns all Person's on the line
  // stops if it hits a wall
  ArrayList<Person> entities = allEntities();

  ArrayList<Person> hitPeople = new ArrayList<Person>();
  IntList alreadyHit = new IntList();    // this keeps track of which zombies have already been hit
  PVector step = target.get();
  step.sub(pos);
  step.setMag(3);
  PVector curPos = pos.get();
  boolean playerHit = false;

  int numSteps = ceil(range/step.mag());

  int c, r;

  for (int s=0; s<numSteps; s++) {
    curPos.add(step);

    c = int((curPos.x - current.topCorner.x)/tSize);
    r = int((curPos.y - current.topCorner.y)/tSize);

    if (!current.map[c][r].transparent) break;    // if it hits a wall, end

    if (you.whichBuilding == current.ID && you.pos.dist(curPos) < you.size/2 && !playerHit && you != seeker) {
      hitPeople.add(you);
    }

    Person temp;
    for (int z=0; z<entities.size (); z++) {
      temp = entities.get(z);
      if (temp.whichBuilding == current.ID && temp.pos.dist(curPos) < temp.size/2 && !alreadyHit.hasValue(z) && temp != seeker) {
        hitPeople.add(temp);
        alreadyHit.append(z);
      }
    }
  }

  Person hitArray[] = new Person[hitPeople.size()];
  Person temp;
  for (int i=0; i<hitPeople.size (); i++) {
    temp = hitPeople.get(i);
    hitArray[i] = temp;
  }

  return hitArray;
}

boolean hasVisibilityLine(PVector start, PVector target) {
  // returns whether or not there is a clear line from start to target
  PVector step = target.get();
  step.sub(start);
  step.setMag(3);
  PVector curPos = start.get();

  int numSteps = ceil(start.dist(target)/step.mag());

  int size = current.map[0][0].size;

  int c, r;

  for (int s=0; s<numSteps; s++) {
    curPos.add(step);

    c = int(curPos.x/size);
    r = int(curPos.y/size);

    if (!current.map[c][r].transparent) return false;    // if it hits a wall, end
  }
  return true;
}

AudioPlayer[] loadManySounds(String text) {
  // loads as many sounds as possible in the format text#.mp3

  ArrayList<AudioPlayer> list = new ArrayList<AudioPlayer>();

  int num = 1;
  File next = dataFile(text + num + ".mp3");  // "loads" a file
  while (next.exists ()) {    // if it exists, load the soundfile
    list.add(minim.loadFile(text+num+".mp3"));
    num++;
    next = dataFile(text+num+".mp3"); 
    // then cycles through until it finds one that doesn't exist
  }

  // then turns into an array
  AudioPlayer[] array = new AudioPlayer[list.size()];
  for (int i=0; i<array.length; i++) array[i] = list.get(i);

  return array;
}

float calcVolume(Person current) {
  // calculates how loud the sound should be played, based on % of maxDist
  float loudness = -30 * constrain(dist(you.pos.x, you.pos.y, current.pos.x, current.pos.y)/maxSoundDist, 0.0, 1.0);
  return loudness;
}

int whichInvSlot(ItemSlot[] slots) {
  // returns which spot was clicked, or -1 if none
  int spot = -1;
  for (int i = 0; i < slots.length; i++) {        
    if (slots[i].hoveredOver()) {
      spot = i;
      break;
    }
  }
  return spot;
}

void resetGame() {
  // regen buildings
  buildings.clear();
  buildings.add(new Building(0, 0, "N"));  // 0 is outside

  // recreate outside
  current = buildings.get(0);
  current.readTile();
  int numZombies = 100;
  current.fillWithZombies(numZombies);

  words1 = "";
  words2 = "";
  words3 = "";
  words4 = "";

  // new journal
  journal = new Journal();
  journal.addPage("");
  journal.addPage(storyline[0]);

  // night stuff reset
  wakeUp = false;

  goToSleep = false;
  timeDay = 0;
  nightWarning = true;
  countdown = dayLength;
  calcNightlyAttack(1);

  // stat reset
  zombiesKilled = 0;
  peopleKilled = 0;
  itemsFound = 0;
  itemsCrafted = 0;
  itemsUsed = 0;
  shotsFired = 0;
  buildingsEntered = 0;
  buildingsCleared = 0;
  pixelsTravelled = 0;
  favWeapon = null;
  for (Item temp : items) {
    if (temp instanceof Weapon) ((Weapon)temp).kills = 0;
  }

  // reset you
  you.whichBuilding = 0;
  you.genSafeCoords(safezones.get(randint(safezones.size())));
  you.name = "";
  you.health = 100;
  you.hunger = 100;
  you.morale = 75;
  for (int i=0; i<you.inventory.length; i++) you.inventory[i] = null;   // clear inventory
  you.equippedWeapon = null;

  textYPos = height;

  up = false;
  down = false;
  left = false;
  right = false;
}

