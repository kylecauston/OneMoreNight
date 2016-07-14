
PVector TRANS;

String deathReason = "";

boolean checkVision = false;

abstract class Gamestate {
  Menu menu;
  abstract void update();
  abstract void keyInput();
  abstract void mouseInput();
  abstract void display();
}

class TitleScreen extends Gamestate {

  TitleScreen() {
    background(0);
    textYPos = height;

    //Integers
    grass = height - 80;

    //Vector
    target = new PVector (0, 0);

    for (int z = 0; z < titleHorde.length; z++) {
      titleHorde[z] = new TitleZombie(random(width), grass - zLeft.height/2);
    }

    for (int d = 0; d < rain.length; d++) {
      rain[d] = new Drop();
    }

    menu = new Menu<Gamestate>(width/2, height/2, true);
    menu.add("Play", customtest);
    menu.add("Controls", controltest);
    menu.add("Credits", credittest);
    menu.add("Quit", quittest);
  }

  void loadTitleAssets() {
  }

  void keyInput() {
    if (key == '4') {
      AudioPlayer sound = zombieMoans[int(random(zombieMoans.length))];
      sound.rewind();
      float vol = random(-20, 0);
      println(vol);
      sound.setGain(vol);
      sound.play();
    } else if (key == '6') {
      AudioPlayer sound = gunshot;
      sound.rewind();
      float vol = random(-20, 0); 
      println(vol);
      sound.setGain(vol);
      sound.play();
    } else if (key == '1') {
      AudioPlayer sound = zombieMoans[int(random(zombieMoans.length))];
      sound.rewind();
      sound.setGain(-20);
      sound.play();
    } else if (key == '3') {
      AudioPlayer sound = gunshot;
      sound.rewind();
      sound.setGain(-20);
      sound.play();
    }
    // empty
  }

  void mouseInput() {
    state = (Gamestate)menu.choose();
    cursor();
  }

  void update() {
    // rain
    for (Drop d : rain) d.update();
    // Zombies following mouse
    target.x = mouseX;
    target.y = grass - titleHorde[0].curPic.height/2;
    for (int z=0; z<titleHorde.length; z++) {
      titleHorde[z].update(target);
    }
  }

  void display() {
    background(0);

    // noCursor();
    pushStyle();
    noStroke();

    //Hills and House
    imageMode(CORNER);
    fill(21, 57, 21); //darkest green
    ellipseMode(CENTER);
    ellipse(width, height, width * 2, height * 2/3);  //Far hill
    fill(27, 75, 27); //dark green
    ellipse(0, height, width * 2, height/2); //Close Hill
    image(house, width/2 + 270, height/2 + 50);

    //Rain
    rectMode(CENTER);
    noStroke();
    for (Drop d : rain) {
      fill(d.col);
      if (!d.inFront) rect(d.x, d.y, 2, 4);
    }

    image(title, 15, 0);

    menu.display();

    for (Drop d : rain) {
      fill(d.col);
      if (d.inFront) rect(d.x, d.y, 2, 4);
    }

    //Grass
    noStroke();
    rectMode(CORNER);
    fill(70, 118, 44);
    rect(0, grass, width, height);

    imageMode(CENTER);
    for (int z = 0; z < titleHorde.length; z++) {
      image(titleHorde[z].curPic, titleHorde[z].x, titleHorde[z].y);
    }

    image(steak, mouseX, mouseY);
    popStyle();
  }
}

class Customize extends Gamestate {
  void keyInput() {
    if (key == ENTER || key == RETURN) {
      state = playtest;
    } else if (key == BACKSPACE && you.name.length() > 0) {
      you.name = you.name.substring(0, you.name.length()-1);
    } else {
      you.name+= key;
    }
  }

  void mouseInput() {
    // empty
  }

  void update() {
    // empty
  }

  void display() {
    pushStyle();
    background(0);
    fill(#FFFFFF);
    textFont(plain);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("Enter your name\n" + you.name, width/2, height/2);
    popStyle();
  }
}

class Controls extends Gamestate {
  float fireFrame = random(campfire.length);
  void keyInput() {
    // empty
  }

  void mouseInput() {
    noCursor();
    state = titletest;
  }

  void update() {
    fireFrame = (fireFrame + 0.2) % campfire.length;
  }

  void display() {
    background(0); 
    fill(255);
    pushStyle();
    textSize(30);
    text("Controls", width/2, height/8);
    image(controls, width*5/9 - 20, height/3 + 50);
    image(survivor, 125, height/2);
    image(campfire[int(fireFrame)], 175 + campfire[int(fireFrame)].width/2 + 10, height/2 + survivor.height/2 - campfire[int(fireFrame)].height/2 + 4);
    popStyle();
  }
}

class Play extends Gamestate {
  ItemSlot weaponSlot;

  Play() {
    weaponSlot = new ItemSlot(676, 339, 115, 115);
  }

  void keyInput() {
    switch (key) {
    case '.':
      you.getItem(nameToID("Planks"));
      you.getItem(nameToID("Music Player"));
      //  countdown = 0;
      break;
    case 'p':
      prevstate = state;
      state = pausetest;
      break;
    case 'b': // show building overview
      if (current.ID != 0) state = overviewtest; 
      break;
    case 'i':    // open inventory
      state = invtest;
      break;
    case 'j': //open journal
      state = journaltest;
      break;        
    case ESC:
      key = 0;
      state = playtest;  
      selectedItems.clear();
      break; 
    case 'f':      // interact/search
      interact(you);
      break;
    case '9':
      //  debug = !debug;
      state = debugtest;
      break;
    case '7':
      you.getItem(nameToID("Nails"));
      you.getItem(nameToID("Planks"));
      break;
    case '0':
      closestEnemy(you).tagged = true;
      break;
    case 'w':
      up = true;
      break;
    case 's':
      down = true;
      break;
    case 'a':
      left = true;
      break;
    case 'd':
      right = true;
      break;
    }
  }

  void keyRelease() {
    switch (key) {
    case 'w':
      up = false;
      break;
    case 's':
      down = false;
      break;
    case 'a':
      left = false;
      break;
    case 'd':
      right = false;
      break;
    }
  }

  void mouseInput() {
    if (weaponSlot.hoveredOver()) {  // unequipping weapon
      if (you.equippedWeapon != null && you.getItem(you.equippedWeapon)) you.equippedWeapon = null;
    } else {
      mouse.set(mouseX, mouseY);
      mouse.sub(TRANS);
      you.attack();
    }
  }

  void update() {
    if (day) {
      countdown -= deltaTime;
      timer();
    } else {
      tilesAcross = ceil((width/tSize/2)/3);
      tilesDown = ceil((height/tSize/2)+1)/3;
    }

    // check if needed to delete music player from inventory
    // usedMusicPlayer only becomes true when input is selected
    if (usedMusicPlayer) {
      int musicID = nameToID("Music Player");
      for (int i=0; i<you.inventory.length; i++) {
        if (you.inventory[i].ID == musicID) {
          you.inventory[i] = null;
          break;
        }
      }
      usedMusicPlayer = false;
    }

    // 50 % hunger per day -> (50.0/dayLength) * deltaTime gives 
    //   an incremental hunger amount 
    you.hunger = max(you.hunger - (50.0/float(dayLength)) * deltaTime, 0);

    if (you.hunger <= 0) {
      you.health = max(you.health - (50.0/float(dayLength)) * deltaTime, 0);
    } 

    if (you.health <= 0) {
      state = deadtest;
      if (you.hunger <= 0) {
        deathReason = "You starved to death.";
      } else {
        deathReason = "You were eaten by zombies.";
      }
    }

    if (song != null && !song.isPlaying()) {
      song = null;
      theme.play();
    }

    ArrayList<Person> entities = allEntities();

    for (Person temp : entities) { 
      if (temp == you) continue;
      if (temp.whichBuilding == current.ID && dist(temp.pos.x, temp.pos.y, you.pos.x, you.pos.y) < updateRadius) {
        temp.update();
      }
    }

    you.update();
  } 

  void display() {
    background(0); 
    TRANS.set(width/2-50-you.pos.x, height/2-you.pos.y); 
    current.showMap(); 

    imageMode(CENTER); 

    pushMatrix(); 
    translate(width/2-50-you.pos.x, height/2-you.pos.y); 

    //image(tempBKG, 0, 0);
    you.display(); 
    pushStyle(); 
    noFill(); 
    stroke(#FFFFFF);  
    if (you.equippedWeapon != null) { 
      int range = you.getRange();
      mouse.set(mouseX, mouseY);
      mouse.sub(TRANS);
      if (you.flashTimer > 0) {
        you.showMuzzleFlash();
      }
    }
    //ellipse(you.pos.x, you.pos.y, range*2, range*2); 
    popStyle(); 

    ArrayList<Person> entity = allEntities(); 
    Person temp;
    for (int i=0; i<entity.size (); i++) { 
      temp = entity.get(i);
      if (temp.whichBuilding == current.ID && dist(temp.pos.x, temp.pos.y, you.pos.x, you.pos.y) < updateRadius) {
        temp.display();
      }
    }

    popMatrix(); 

    drawHud();
  }
}

class Debug extends Play {
  final int ZOMBIE = -1;
  final int CIVILIAN = -2;
  PVector mouseCoords;
  int row, col;
  int[] spawnType;
  int spawnCounter = 0;
  Behavior[] defaultBehaviors;
  int behaviorCounter = 0;
  NPC highlighted;

  boolean visionCones, enemyLine, pathLines =true, stateDisplay, tileInfo, entitySpawn, mapInfo, safezoneDisplay=true, highlightedInfo;

  Debug() {
    mouseCoords = new PVector();

    highlighted = null;

    spawnType = new int[2];
    spawnType[0] = ZOMBIE;
    spawnType[1] = CIVILIAN;

    defaultBehaviors = new Behavior[4];
    defaultBehaviors[0] = wander;
    defaultBehaviors[1] = chase;
    defaultBehaviors[2] = wait;
    defaultBehaviors[3] = flee;
  }

  void keyInput() {
    if (key == CODED) {
      if (keyCode == UP) spawnCounter = cycleUp(spawnCounter, spawnType.length);
      if (keyCode == DOWN) spawnCounter = cycleDown(spawnCounter, spawnType.length);
      if (keyCode == RIGHT) behaviorCounter = cycleUp(behaviorCounter, defaultBehaviors.length);
      if (keyCode == LEFT) behaviorCounter = cycleDown(behaviorCounter, defaultBehaviors.length);
    } else {
      switch(key) {
      case '9':
        state = playtest;
        break;
      case 'p':
        state = debugpause;
        break;
      case 'r':
        current.readTile();
        break;
      case ' ':
        countdown = 0;
        break;
      case 'f':
        if (highlighted != null) highlighted.setBehavior(flee);
        break;
      case DELETE:
        if (highlighted != null) {
          highlighted.health = 0;
          highlighted = null;
        }
        break;
      default:
        debugpause.keyInput();
        super.keyInput();
      }
    }
  }

  void mouseInput() {
    if (mouseButton == LEFT) {
      highlighted = null;
      ArrayList<Person> entities = allEntities();
      Person temp;
      for (int i=0; i<entities.size (); i++) {
        temp = entities.get(i);
        if (temp == you) continue;
        if (temp.hoveredOver(mouseCoords)) { 
          highlighted = (NPC)temp;
          break;
        }
      }
    } else if (mouseButton == RIGHT) {
      if (highlighted != null) {
        highlighted.nextBehavior = wait;
        highlighted.goToTarget(mouseCoords, wait);
      } else {
        switch(spawnType[spawnCounter]) {
        case ZOMBIE:
          current.zombies.add(new Zombie(current.ID, mouseCoords, defaultBehaviors[behaviorCounter]));
          break;

        case CIVILIAN:
          current.survivors.add(new Civilian(current.ID, mouseCoords, defaultBehaviors[behaviorCounter]));
          break;
        }
      }
    }

    super.mouseInput();
  }

  void update() {
    super.update(); 
    mouseCoords.set(round(mouseX-TRANS.x), round(mouseY-TRANS.y)); 
    col = floor(mouseCoords.x/tSize); 
    row = floor(mouseCoords.y/tSize);
  }

  void display() {
    super.display(); 
    pushStyle(); 

    // entity displays
    pushMatrix(); 
    translate(TRANS.x, TRANS.y); 

    ArrayList<Person> entity = allEntities(); 
    Person temp; 
    for (int i=0; i<entity.size (); i++) {
      temp = entity.get(i);
      if (temp.whichBuilding == current.ID && dist(temp.pos.x, temp.pos.y, you.pos.x, you.pos.y) < updateRadius) {
        temp.debugDisplay(visionCones, enemyLine, pathLines, stateDisplay);
      }
    }

    // safe zones
    if (safezoneDisplay) {
      if (current.ID == 0) {
        noFill();
        rectMode(CORNER);
        Safezone zone = closestSafezone(you);  // only displays the closest safezone

        stroke(#FF0015);
        for (Tile tile : zone.openings) rect(tile.pos.x, tile.pos.y, tSize, tSize); // openings

        stroke(#11F0DB);
        for (Tile tile : zone.spots) rect(tile.pos.x, tile.pos.y, tSize, tSize);  // safe zone
        //
        stroke(#0008FF);
        //     rect(zone.topLeft, zone.bottomRight);  // outlining the safezone
        ellipse(zone.centerpoint.x, zone.centerpoint.y, 10, 10);   // centerpoint display
        line(you.pos, zone.centerpoint);  // line to safezone
      }
    }

    // tile highlighting
    if (tileInfo) {
      noFill();
      strokeWeight(2);
      stroke(#FFFFFF); 
      rectMode(CORNERS); 
      rect(col*tSize, row*tSize, (col+1)*tSize, (row+1)*tSize);
    }

    // person highlighting
    noFill();
    stroke(#C5E01B);
    strokeWeight(2);
    if (highlighted != null && highlighted.whichBuilding == current.ID) {
      ellipse(highlighted.pos.x, highlighted.pos.y, highlighted.size, highlighted.size);
      strokeWeight(1);
      highlighted.debugDisplay(true, true, true, true);
    }

    // building corners
    noStroke();
    fill(#F011E1); 
    ellipse(current.topCorner.x, current.topCorner.y, 10, 10); 
    ellipse(current.bottomCorner.x, current.bottomCorner.y, 10, 10); 
    rectMode(CORNERS);
    noFill();
    stroke(#F011E1);
    strokeWeight(1);
    rect(current.topCorner.x, current.topCorner.y, current.bottomCorner.x, current.bottomCorner.y);

    popMatrix(); 

    // text setup
    textSize(14); 
    fill(#FFFFFF); 
    textAlign(LEFT, TOP); 

    rectMode(CORNER); 
    fill(#FFFFFF, 75); 
    strokeWeight(2); 
    stroke(#000000);

    // tile window
    if (tileInfo) {
      PVector tileWindow = new PVector(width - 375, 400); 
      int twHeight = 150; 
      int twWidth = 225; 

      rectMode(CORNER); 
      fill(#FFFFFF, 75); 
      strokeWeight(2); 
      stroke(#000000); 
      rect(tileWindow.x, tileWindow.y, twWidth, twHeight); 

      fill(#000000); 
      textAlign(CENTER, TOP); 
      text("Tile", tileWindow.x+twWidth/2, tileWindow.y+5); 

      textAlign(LEFT, TOP); 
      text("Mouse Coords: " + mouseX + " " + mouseY, tileWindow.x+5, tileWindow.y+25); 
      text("Trans Coords: " + int(mouseCoords.x) + " " + int(mouseCoords.y), tileWindow.x+5, tileWindow.y+40); 
      text("Row: " + row + " Col: " + col, tileWindow.x+5, tileWindow.y+55); 
      String solid = "-"; 
      String transparent = "-"; 
      String safe = "-"; 
      String item = "-"; 
      String fromText = "-";
      if (row >= 0 && col >= 0 && row < current.rows && col < current.cols) {
        solid = "No"; 
        transparent = "No"; 
        safe = "No"; 
        item = "Empty"; 

        Tile tile = current.map[col][row]; 
        if (tile.solid) solid = "Yes"; 
        if (tile.transparent) transparent = "Yes"; 
        if (tile.safe) safe = "Yes"; 
        if (tile.loot != -1) item = items.get(tile.loot).name;
        fromText = tile.mapText;
      }
      text("Solid: " + solid, tileWindow.x+5, tileWindow.y+70); 
      text("Transparent: " + transparent, tileWindow.x+5, tileWindow.y+85); 
      text("Safe: " + safe, tileWindow.x+5, tileWindow.y+100); 
      text("Loot: " + item, tileWindow.x+5, tileWindow.y+115);
      text("Tile String: " + fromText, tileWindow.x+5, tileWindow.y+130);
    }

    if (entitySpawn) {
      // spawn window
      PVector spawnWindow = new PVector(5, 450); 
      int Width = 200; 
      int Height = 75; 

      rectMode(CORNER);
      fill(#FFFFFF, 75); 
      strokeWeight(2); 
      stroke(#000000); 
      rect(spawnWindow.x, spawnWindow.y, Width, Height); 

      fill(#000000); 
      textAlign(CENTER, TOP); 
      text("Spawning Entity", spawnWindow.x+Width/2, spawnWindow.y+5); 

      String entityString = "";
      switch(spawnType[spawnCounter]) {
      case ZOMBIE:
        entityString = "Zombie";
        break;
      case CIVILIAN:
        entityString = "Civilian";
        break;
      }

      textAlign(LEFT, TOP); 
      text("Entity: " + entityString, spawnWindow.x+5, spawnWindow.y+25); 
      text("Default Behavior: " + defaultBehaviors[behaviorCounter].name, spawnWindow.x+5, spawnWindow.y+40);
    }

    if (mapInfo) {
      PVector mapWindow = new PVector(5, 5);
      int h = 95;
      int w = 200;

      rectMode(CORNER);
      fill(#FFFFFF, 75); 
      strokeWeight(2); 
      stroke(#000000); 
      rect(mapWindow.x, mapWindow.y, w, h); 

      fill(#000000); 
      textAlign(CENTER, TOP); 
      text("Map Info", mapWindow.x+w/2, mapWindow.y+5);

      textAlign(LEFT, TOP);
      text("Map String: " + current.mapText, mapWindow.x+5, mapWindow.y+25);
      text("Zombie Count: " + current.zombies.size(), mapWindow.x+5, mapWindow.y+40);
      text("Survivor Count: " + current.survivors.size(), mapWindow.x+5, mapWindow.y+55);
      text("Frame Rate: " + nf(frameRate, 0, 0), mapWindow.x+5, mapWindow.y + 70);
    }

    if (entitySpawn) {
      // spawn window
      PVector window = new PVector(250, 5); 
      int Width = 200; 
      int Height = 75; 

      rectMode(CORNER);
      fill(#FFFFFF, 75); 
      strokeWeight(2); 
      stroke(#000000); 
      rect(window.x, window.y, Width, Height); 

      fill(#000000); 
      textAlign(CENTER, TOP); 
      text("Highlighted Entity", window.x+Width/2, window.y+5); 

      String text = (highlighted == null) ? "-" : Float.toString(highlighted.speed);

      textAlign(LEFT, TOP);
      text("Speed: " + text, window.x+5, window.y+25);
    }

    if (safezoneDisplay) {
      PVector safeZoneWindow = new PVector(width - 300, 5); 
      int wHeight = 100; 
      int wWidth = 150; 

      rectMode(CORNER); 
      fill(#FFFFFF, 75); 
      strokeWeight(2); 
      stroke(#000000); 
      rect(safeZoneWindow.x, safeZoneWindow.y, wWidth, wHeight); 

      fill(#000000); 
      textAlign(CENTER, TOP); 
      text("Safezone", safeZoneWindow.x+wWidth/2, safeZoneWindow.y+5);

      Safezone zone = closestSafezone(you);  // only displays the closest safezone

      textAlign(LEFT, TOP);
      text("Survivor Count: " + zone.survivors.size(), safeZoneWindow.x+5, safeZoneWindow.y+25);
      text("Guards on Duty: " + zone.numGuards, safeZoneWindow.x+5, safeZoneWindow.y+40);
      text("Need Guard? " + zone.needsGuard(), safeZoneWindow.x+5, safeZoneWindow.y+55);
    }

    popStyle();
  }
}

class DebugPause extends Debug {
  final char toggleVision = '1';
  final char toggleEnemy = '2';
  final char togglePath = '3';
  final char toggleState = '4';
  final char toggleTileInfo = '5';
  final char toggleSpawn = '6';
  final char toggleMap = '7';
  final char toggleSafe = '8';
  void keyInput() {
    switch(key) {
    case toggleVision:
      ((Debug)debugtest).visionCones = !((Debug)debugtest).visionCones;
      visionCones = !visionCones;
      break;
    case toggleEnemy:
      ((Debug)debugtest).enemyLine = !((Debug)debugtest).enemyLine;
      enemyLine = !enemyLine;
      break;
    case togglePath:
      ((Debug)debugtest).pathLines = !((Debug)debugtest).pathLines;
      pathLines = !pathLines;
      break;
    case toggleState:
      ((Debug)debugtest).stateDisplay = !((Debug)debugtest).stateDisplay;
      stateDisplay = !stateDisplay;
      break;
    case toggleTileInfo:
      ((Debug)debugtest).tileInfo = !((Debug)debugtest).tileInfo;
      tileInfo = !tileInfo;
      break;
    case toggleSpawn:
      ((Debug)debugtest).entitySpawn = !((Debug)debugtest).entitySpawn;
      entitySpawn = !entitySpawn; 
      break;
    case toggleMap:
      ((Debug)debugtest).mapInfo = !((Debug)debugtest).mapInfo;
      mapInfo = !mapInfo;
      break;
    case toggleSafe:
      ((Debug)debugtest).safezoneDisplay = !((Debug)debugtest).safezoneDisplay;
      safezoneDisplay = !safezoneDisplay;
      break;
    case 'p':
      state = debugtest;
      break;
    case '9':
      state = playtest;
      break;
    }
  }

  void mouseInput() {
  }

  void update() {
    super.update();
  }

  void display() {
    super.display();

    pushStyle();
    fill(#000000, 150);
    rect(0, 0, width, height);

    PVector toggles = new PVector(100, 150);

    color green = #18E507;
    color red = #F71C14;
    fill(red);
    if (visionCones) fill(green);
    ellipse(toggles, 20);
    fill(red);
    if (enemyLine) fill(green);
    ellipse(toggles.x, toggles.y+50, 20, 20);
    fill(red);
    if (pathLines) fill(green);
    ellipse(toggles.x, toggles.y+100, 20, 20);
    fill(red);
    if (stateDisplay) fill(green);
    ellipse(toggles.x, toggles.y+150, 20, 20);
    fill(red);
    if (tileInfo) fill(green);
    ellipse(toggles.x, toggles.y+200, 20, 20);
    fill(red);
    if (entitySpawn) fill(green);
    ellipse(toggles.x, toggles.y+250, 20, 20);
    fill(red);
    if (mapInfo) fill(green);
    ellipse(toggles.x, toggles.y+300, 20, 20);
    fill(red);
    if (safezoneDisplay) fill(green);
    ellipse(toggles.x, toggles.y+350, 20, 20);

    fill(#FFFFFF);
    textSize(18);
    textAlign(LEFT, CENTER);
    text(toggleVision + " : Toggle Vision Cones", toggles.x-5, toggles.y);
    text(toggleEnemy + " : Toggle Enemy Lines", toggles.x-5, toggles.y+50);
    text(togglePath + " : Toggle Path Lines", toggles.x-5, toggles.y+100);
    text(toggleState + " : Toggle State Display", toggles.x-5, toggles.y+150); 
    text(toggleTileInfo + " : Toggle Tile Info", toggles.x-5, toggles.y+200);
    text(toggleSpawn + " : Toggle NPC Spawn Info", toggles.x-5, toggles.y+250);
    text(toggleMap + " : Toggle Map Info", toggles.x-5, toggles.y+300);
    text(toggleSafe + " : Toggle Safezone Display", toggles.x-5, toggles.y+350);
    popStyle();
  }
}

class Sleep extends Play {
  // actual black part, with sounds n shit. 
  int pauseTime = 5000; // 5 seconds

  void keyInput() {
    // empty
  }

  void mouseInput() {
    // empty
  }

  void update() {
    if (pauseTime > 0) {
      pauseTime -= deltaTime; 
      // play random sounds
      AudioPlayer sound = zombieMoans[int(random(zombieMoans.length))]; 
      if (!sound.isPlaying()) {
        sound.rewind(); 
        sound.setGain(0); 
        sound.play();
      } else {
        sound = zombieGrowls[int(random(zombieGrowls.length))]; 
        if (!sound.isPlaying()) {
          sound.rewind(); 
          sound.setGain(0); 
          sound.play();
        } else {
          sound = nightBanging[int(random(nightBanging.length))]; 
          if (!sound.isPlaying()) {
            sound.rewind(); 
            sound.setGain(0); 
            sound.play();
          }
        }
      }
    } else {
      for (AudioPlayer sound : nightBanging) sound.pause(); 
      for (AudioPlayer sound : zombieMoans) sound.pause(); 
      for (AudioPlayer sound : zombieGrowls) sound.pause(); 

      if (song == null)  theme.play(); // if no song was playing

      pauseTime = 5000;

      sleep(timeDay+1); 
      wakeUp = true; 
      day = true; 
      countdown = dayLength; 
      timeDay++; 
      state = waketest;
    }
  }
  void display() {
    background(0);
  }
}

class WakeUp extends Play {
  float screenFade = 255; 
  final float fadeIncrement = 2.5; 
  // fades in to world

  void keyInput() {
    // empty
  }

  void mouseInput() {
    // empty
  }

  void update() {
    tilesAcross = ceil(width/tSize/2);
    tilesDown = ceil(height/tSize/2)+1;

    if (screenFade > 0) {
      screenFade -= fadeIncrement;
    } else {
      screenFade = 255;
      state = playtest;
    }
  }

  void display() {
    super.display(); 
    fill(#000000, screenFade); 
    rect(0, 0, width, height);
  }
}

class InventoryState extends Play {

  final int INVX = 35;
  final int INVY = 30;
  final int INVW = 600;
  final int INVH = 500;
  final int BOXW = INVW/6; 
  final int BOXH = BOXW;

  final int numItemSlots = 12;
  ItemSlot[] inventorySlots = new ItemSlot[numItemSlots];

  InventoryState() {
    final int xSpace = 40;
    final int ySpace = 45;
    int tempx = INVX + xSpace;
    int tempy = INVY + ySpace + 20;

    for (int i = 0; i < numItemSlots; i++) {
      inventorySlots[i] = new ItemSlot(0, 0, BOXW, BOXH);

      //x value
      inventorySlots[i].x = tempx;
      tempx += xSpace + BOXW;

      //y value
      inventorySlots[i].y = tempy;
      if (i == 3 || i == 7) {
        tempy += ySpace + BOXH;
        //Reset the x position
        tempx = INVX + xSpace;
      }
    }
  }

  void keyInput() {
    if (key == 'c') {
      crafting = true;
      state = craftingtest;
    } else if (key == 'i') { 
      selectedItems.clear(); 
      crafting = false;
      state = playtest;
    } else {
      super.keyInput();
    }
  }

  void mouseInput() {
    int spot = whichInvSlot(inventorySlots); 
    if (spot != -1) {    // valid spot clicked
      if (you.inventory[spot] != null) {  // there is an item
        Item temp = you.inventory[spot]; // find the item
        if (mouseButton == LEFT) { // Left click (normal)
          if (temp.use(you)) {
            you.inventory[spot] = null;
            you.getItem(temp.getReturnItem());
          }
        } else if (mouseButton == RIGHT) { // Right click (special)
          you.inventory[spot] = null; 
          console(temp.name + connectingWord(temp.name) + "discarded.");
        }
      }
    } else {
      super.mouseInput();
    }
  }

  void update() {
    super.update(); // update background
  }

  void display() {
    super.display(); 
    pushStyle();
    textFont(plain); 
    final int text = 30;

    //Draws the box
    pushMatrix();
    resetMatrix();
    pushStyle();  
    rectMode(CORNER);

    //Draws the box
    if (crafting) {
      fill(#EA9A05);
      noStroke();
      rect(INVX-5, INVY-5, INVW+10, INVH+10);
    }

    fill(#766A54);
    stroke(#554932);
    strokeWeight(4);
    rect(INVX, INVY, INVW, INVH);

    //Draws each Box
    textAlign(CENTER, TOP);
    imageMode(CORNER);
    Item currItem;
    for (int i = 0; i < numItemSlots; i++) {
      if (crafting) {
        pushStyle();
        fill(#EA9A05);
        noStroke();
        if (selectedItems.hasValue(i)) {
          rect(inventorySlots[i].x-5, inventorySlots[i].y-5, BOXW+10, BOXH+10);
        }
        popStyle();
      }
      textSize(16);
      inventorySlots[i].display();
      if (you.inventory[i] != null) {
        currItem = (you.inventory[i]);
        image(currItem.pic, inventorySlots[i].x, inventorySlots[i].y);
        fill(#554932);
        text(currItem.name, inventorySlots[i].x + BOXW/2, inventorySlots[i].y + BOXH + 10);
        fill(#FFFFFF);
        text(currItem.ran, inventorySlots[i].x+10, inventorySlots[i].y);
      }
    }      

    //Fancy Bar
    fill(#554932);
    noStroke();
    rect(INVX, INVY, INVW, text + 10);

    //Title
    textSize(25);
    fill(#C6B698);
    textAlign(CENTER, TOP);
    text("Inventory", INVX + INVW/2, INVY + 8);

    textSize(15);
    fill(#EA9A05);
    textAlign(CENTER, RIGHT);
    text("Craft (c)", INVX + INVW - 40, INVY + 25);

    popStyle();
    popMatrix();
    popStyle();
  }
}

class CraftingState extends InventoryState {
  final color dark = color(#554932); 
  final color grey = color(#C6B698); 

  CraftingState() {
    selectedItems = new IntList();
  }

  void keyInput() {
    if (key == 'c') { 
      selectedItems.clear();
      crafting = false;
      state = invtest;
    } else {
      super.keyInput();
    }
  }

  void mouseInput() {
    int spot = whichInvSlot(inventorySlots); 
    if (spot != -1) { // found spot
      if (you.inventory[spot] != null) {
        if (mouseButton == LEFT) {
          if (!selectedItems.hasValue(spot)) {  // if this spot isn't already picked
            selectedItems.append(spot); // add it
          } else {    // if it has been picked
            you.craft(selectedItems, currCraft); // craft it
            selectedItems.clear(); // clear the list
          }
        } else if (mouseButton == RIGHT) {    // deselecting
          if (selectedItems.hasValue(spot)) {  
            int slot; 
            for (int j=0; j<selectedItems.size (); j++) {
              slot = selectedItems.get(j); 
              if (slot == spot) {
                selectedItems.remove(j); 
                break;
              }
            }
          }
        }
        currCraft = whichCraft(selectedItems);
      }
    } else {
      super.mouseInput();
    }
  }

  void update() {
    super.update();
  }

  void display() {
    // only displays inventory screen + background, but crafting = true so there is orange borders
    invtest.display(); 
    if (selectedItems.size() > 0) {
      fill(grey, 200); 
      rect(mouseX+10, mouseY+10, 200, 25); 
      fill(dark, 200); 
      textAlign(LEFT, TOP); 
      textSize(16); 
      if (currCraft == null) {
        text("Crafts: nothing", mouseX+15, mouseY + 15);
      } else {
        Item tempItem = items.get(currCraft.result); 
        text("Crafts: " + tempItem.name, mouseX+15, mouseY+15);
      }
    }
  }
}

class BuildingOverview extends Play {
  final PVector pos = new PVector(35, 30);
  final int W = 600;
  final int H = 500;
  final int divLine = W - 250;
  final PVector sleepButton = new PVector(510, 450);
  ItemSlot[] slots;

  BuildingOverview() {
    slots = new ItemSlot[6];
    int[] x = new int [2];
    int[] y = new int [3];
    int itemSize = ((InventoryState)invtest).BOXW;

    float buffer = (divLine - x.length*itemSize)/(x.length + 1);
    for (int i=0; i<x.length; i++) x[i] = int(pos.x + (i+1)*buffer + (i*itemSize));

    buffer = (H - y.length*itemSize) / (y.length + 1);
    for (int i=0; i<y.length; i++) y[i] = int(pos.y + (i+1)*buffer + (i*itemSize));

    for (int i=0; i<y.length*x.length; i++) slots[i] = new ItemSlot(0, 0, itemSize, itemSize);

    for (int i=0; i<slots.length; i++) {
      // every second item gets x[1]
      slots[i].x = x[i % 2];
      slots[i].y = y[floor(i/2)];
    }
  }

  void keyInput() {
    if (key == 'b') {
      state = playtest;
    } else {
      super.keyInput();
    }
  }

  void mouseInput() {
    if (!day && dist(mouseX, mouseY, sleepButton.x, sleepButton.y) < sleepingBag.width/2) {
      state = fallasleeptest;
    } else {
      int boxnum = -1;
      for (int i=0; i<slots.length; i++) {
        if (slots[i].hoveredOver()) {
          boxnum = i;
          continue;
        }
      }

      if (boxnum != -1 && current.furnishings[boxnum] != null) { // clicked a non empty box
        if (mouseButton == LEFT) {
          current.furnishings[boxnum].interact();
        } else if (mouseButton == RIGHT) {
          current.removeFurnishing(boxnum);
        }
      } else {
        super.mouseInput();
      }
    }
  }


  void update() {
    super.update();
  }

  void display() {
    super.display(); 
    showOverview(current);
  }

  void showOverview(Building b) {
    pushStyle();

    // backdrop
    rectMode(CORNER);
    stroke(#554932);
    strokeWeight(8);
    fill(#766A54);
    rect(pos.x, pos.y, W, H);
    line(pos.x + divLine, pos.y+1, pos.x + divLine, pos.y+H-1);

    // name of building
    fill(#C6B698);
    textFont(plain);
    textSize(26);
    textAlign(CENTER, TOP);
    text(b.name, pos.x + divLine/2, pos.y+15);

    // building info - left side
    textAlign(LEFT, TOP);
    textSize(22);
    float curY = pos.y + 15; // counter for text

    text("Building Stats", pos.x + divLine + 15, curY);
    curY += 50;
    textSize(20);
    text("Defense: " + b.def, pos.x + divLine + 15, curY);
    curY += 25;
    text("Max Def: " + b.maxDef, pos.x + divLine + 15, curY);
    curY += 50;
    text("Night " + (timeDay + 1), pos.x + divLine + 15, curY);
    curY += 25;
    text("Zombies: " + minZombies + "-" + maxZombies, pos.x + divLine + 15, curY);

    String warning;
    if (b.def < minZombies) {  // not even close
      warning = "You're gonna have a horrible night with those defenses.";
    } else if (b.def > maxZombies) { // super safe
      warning = "You should be fine.";
    } else { // in the middle
      warning = "You're really risking it eh? Good luck.";
    }
    if (!b.isEmpty()) warning = "Are you honestly gonna sleep with those zombies in here?";

    rectMode(CORNERS);
    textAlign(CENTER, TOP);
    curY += 150;
    text(warning, pos.x + divLine + 15, curY, pos.x + W - 15, curY + 100);

    imageMode(CENTER);
    image(sleepingBag, sleepButton.x, sleepButton.y);
    fill(#766A54, 200);
    noStroke();
    if (day || !b.isEmpty()) ellipse(sleepButton.x, sleepButton.y, sleepingBag.width, sleepingBag.height);

    // items - left side

    textFont(plain); 
    textSize(16);
    fill(#766A54);
    imageMode(CORNER);
    textAlign(CENTER, TOP);

    for (int i=0; i<slots.length; i++) {
      slots[i].display();
      if (b.furnishings[i] != null) {
        image(b.furnishings[i].getImage(), slots[i].x, slots[i].y);
        text(b.furnishings[i].getAction() + " " + b.furnishings[i].name.toLowerCase(), slots[i].x + slots[i].w/2, slots[i].y + slots[i].h + 10);
      }
    }

    popStyle();
  }
}

class FallAsleep extends BuildingOverview {
  float screenFade = 0; 
  final float fadeIncrement = 2.5; 

  void keyInput() {
    // empty
  }
  void mouseInput() {
    // empty
  }
  void update() {
    if (screenFade < 255) {
      screenFade += fadeIncrement;
    } else {    // if it's done fading out
      screenFade = 0;
      theme.pause(); 
      state = sleeptest;
    }
  }
  void display() {
    super.display(); 
    fill(#000000, screenFade); 
    rect(0, 0, width, height);
  }
}

class JournalState extends Play {
  void keyInput() {
    if (key == CODED) {
      if (keyCode == LEFT) journal.prevPage(); 
      if (keyCode == RIGHT) journal.nextPage();
    }
    if (key == 'j') {
      state = playtest;
    } else {
      super.keyInput();
    }
  }
  void mouseInput() {
    super.mouseInput();
  }
  void update() {
    super.update();
  }
  void display() {
    super.display(); 
    journal.display();
  }
}

class Pause extends Play {
  void keyInput() {
    if (key == 'p') state = prevstate;
  }
  void mouseInput() {
    // empty
  }
  void update() {
    // empty
  }
  void display() {
    prevstate.display(); 
    pushMatrix(); 
    fill(#000000, 150); 
    rect(0, 0, width, height); 
    fill(#FFFFFF); 
    textFont(plain); 
    textSize(26); 
    textAlign(CENTER, CENTER); 
    text("Paused", width/2 - 50, height/2); 
    popMatrix();
  }
}

class Dead extends Gamestate {

  void keyInput() {
    // empty
  }
  void mouseInput() {
    state = credittest;
  }
  void update() {
    target.x = mouseX; 
    target.y = grass - titleHorde[0].curPic.height/2; 
    for (int z=0; z<titleHorde.length; z++) {
      titleHorde[z].update(target);
    }
  }
  void display() {
    background(0); 
    textFont(plain); 
    textAlign(CENTER, BOTTOM); 
    fill(255); 
    image(gameover, width/2, 150); 
    text(deathReason + "\nYou have fallen after " + timeDay + " days.\n\nClick anywhere to continue", width/2, height*3/5); 

    //Grass
    fill(#486A25); //green
    rectMode(CORNER); 
    noStroke(); 
    rect(0, grass - 5, width, height * 1/6); 

    imageMode(CENTER); 
    for (int z = 0; z < titleHorde.length; z++) {
      image(titleHorde[z].curPic, titleHorde[z].x, titleHorde[z].y);
    }
  }
}

class Credits extends Gamestate {
  int survX = 50; 
  float fireFrame = random(campfire.length); 

  void keyInput() {
    // empty
  }
  void mouseInput() {
    resetGame(); 
    noCursor(); 
    state = titletest;
  }
  void update() {
    textYPos -= 1; 
    fireFrame = (fireFrame + 0.25) % campfire.length;
  }

  void display() {
    pushStyle(); 
    background(0); //55, 57, 54);
    textAlign(TOP, CENTER); 
    textFont(plain, 15); 
    fill(#FFFFFF); 

    for (int l = 0; l < credits.length; l++) {
      text(credits[l], width/3, textYPos + 35*l);
    }

    imageMode(CENTER); 
    image(survivor, survX, height/2); 

    image(campfire[int(fireFrame)], survX + survivor.width/2 + campfire[int(fireFrame)].width/2 + 10, height/2 + survivor.height/2 - campfire[int(fireFrame)].height/2 + 4); 
    popStyle();
  }
}

class Quit extends Gamestate {
  // simply exits the game
  void keyInput() {
    // empty
  }
  void mouseInput() {
    // empty
  }
  void update() {
    exit();
  }
  void display() {
    // empty
  }
}

