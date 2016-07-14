
/*  Current Problems/Necessary Add-ons
 
 Find: ADD
 - commented in areas that have addons
 
 - BALANCE
 - make maps
 - make tiles
 - story
 
 - fill out state managers >.< :'(
 
 - less zombies per tile
 - less beginning zombies
 - >> "too hard" greg
 
 - tutorial 
 - >> zombie nearby
 - >> weapon/inv management
 - >> crafting
 
 - increase number of weapon sounds/art
 
 - character customization
 - >> load in picture?
 - >> name
 
 - redo items/inventory 
 - >> gives a copy of the item opposed to the item from list
 - >> this will allow for item individuality (customization, naming, ammo, attatchments)
 - add reusable items
 - >> accomplished by adding a return item
 - add tools
 - >> when crafted, not removed
 
 - Combat
 - >> ammo?
 - >> accuracy?
 - >> hit animation (gun shot, swing)
 
 - misc lore
 - >> previous players stats as lore!! :D
 
 - zombie with negative knockback, pulling you closer
 
 - lockpicking 
 - >> use mouse to turn tumbler, keys to change pin, and keys to move pin up and down
 
 - improve efficiency
 - >> replace DFS with BFS
 - >> definitely replace GridMath.clearMap() with specialized clear methods
 - >> replace image hashmap? inefficient especially with amount it is being called
 - >>> possibly just give each tile it's own PImage
 
 - possibly use knockedBack(Person) to handle state changing involved with being hit/hostility etc
 
 - add decorations
 - >> PImages with transparent backgrounds, rotated to set amount
 
 - redo statistics
 - >> hashmap<String, Integer> ?
 - >>> could improve efficiency by not using .get every frame, and only writing journal page when stat is updated
 - >> array? with constants
 
 - add dialogue
 - >> dialogue state
 - >> trigger handler
 
 */

Player you;

float updateRadius;    // only update zombies that are within this area

Gamestate titletest;
Gamestate customtest;
Gamestate playtest;
Gamestate debugtest;
Gamestate debugpause;
Gamestate pausetest;
Gamestate controltest;
Gamestate credittest;
Gamestate deadtest;
Gamestate quittest;

Gamestate invtest;
Gamestate craftingtest;
Gamestate overviewtest;
Gamestate journaltest;

Gamestate fallasleeptest;
Gamestate sleeptest;
Gamestate waketest;

Gamestate state;
Gamestate prevstate; // for pausing 

void setup() {
  time = millis();
  size(800, 650);

  // loadAverages_file = createWriter("data/LoadTimes.txt");

  String[] pairs = split(loadStrings("data/LoadTimes.txt")[0], ",");
  String[] parts;
  // i=0 is number of values used to compute average
  for (int i=1; i<pairs.length; i++) {
    parts = split(pairs[i], ":");
    oldLoadTimeAverage.put(parts[0], float(parts[1]));
  }

  // load assets
  setupAss();
  loadTime("Assets");

  // load title
  titletest = new TitleScreen();
  loadTime("Title Screen");

  //  theme.play();
  //  theme.loop();

  // initialize screen/display variables
  tilesAcross = ceil(width/tSize/2);
  tilesDown = ceil(height/tSize/2)+1;
  updateRadius = dist(width/2, height/2, width, height) * 1.2;
  maxSoundDist = dist(0, 0, width/2, height/2);

  countdown = dayLength;

  time = millis();

  // load items
  items = new ArrayList<Item>();
  lore = new Material("Lore");
  items.add(lore);
  loadItems();
  loadTime("Items");

  // loading recipes
  recipes = new ArrayList<Recipe>();
  selectedItems = new IntList();
  loadRecipes();
  loadTime("Recipes");

  // load and create map
  readPresets();
  buildings = new ArrayList<Building>();
  buildings.add(new Building(0, 0, "N"));  // 0 is outside
  current = buildings.get(0);
  current.readTile();
  loadTime("Outside");

  // initalize behaviors
  wander = new Wander();
  chase = new Chase();
  totarg = new GoTo();
  wait = new Wait();
  flee = new Flee();

  // load safezones
  loadSafezones();
  loadTime("Safezones");

  // load and fill with entities
  //current.fillWithZombies(1);
  //current.fillWithSurvivors(10);
  // for (Safezone zone : safezones) zone.addSurvivors(3);
  loadTime("Entity filling");
  // maxSoundDist = dist(0, 0, width/2, height/2);

  // set up player
  TRANS = new PVector(0, 0);
  you = new Player(width/2, height/2);
  you.genSafeCoords(safezones.get(randint(safezones.size())));
  you.getItem(nameToID("Grenade"));
  you.getItem(nameToID("Pistol"));
  you.getItem(nameToID("Shotgun"));
  you.getItem(nameToID("Pistol"));
  loadTime("Player setup");


  //you.pos = current.zombies.get(0).pos.get();

  loadStory();

  journal = new Journal();
  journal.addPage("");
  journal.addPage(storyline[0]);
  loadTime("Story and Journal");

  // writeAverages();

  calcNightlyAttack(1);  

  theme.pause();

  // initialize states
  customtest = new Customize();
  playtest = new Play();
  pausetest = new Pause();
  debugtest = new Debug();
  debugpause = new DebugPause();
  controltest = new Controls();
  credittest = new Credits();
  deadtest = new Dead();
  quittest = new Quit();

  invtest = new InventoryState();
  craftingtest = new CraftingState();
  overviewtest = new BuildingOverview();
  journaltest = new JournalState();

  fallasleeptest = new FallAsleep();
  sleeptest = new Sleep();
  waketest = new WakeUp();

  titletest = new TitleScreen();

  state = titletest;
  noCursor();
}

void draw() {
  state.update();
  state.display();
  deltaTime = millis() - time; 
  time = millis();
}

void keyPressed() {
  state.keyInput();
}

void keyReleased() {
  ((Play)playtest).keyRelease();
}

void mousePressed() {
  state.mouseInput();
}

