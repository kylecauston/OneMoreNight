// class is used for both zombies and people

float maxSoundDist;   // farthest zombies can make sound from

PVector mouse = new PVector(mouseX, mouseY);

boolean up = false;
boolean left = false;
boolean down = false;
boolean right = false;

float visionAngle = radians(45);

abstract class Person {

  // need to update collision to only stop knockback.x or y based on which wall

  boolean tagged = false;

  final int size = 20;
  PVector pos;
  PVector vel;
  float speed;
  int cooldown = 0;    // hit cooldown

  String name = "";
  float health, maxHealth = 100;
  float flashTimer = 0;
  final float flashLength = 50;

  int whichBuilding;  // keeps track of the ID of the building that NPC is in
  Weapon equippedWeapon;

  // "fist" stats, different for people vs zombies
  int baseDamage; // = 50;
  int baseRange; //= 25;
  int baseKnockback; //= 100;
  int baseCooldown; //= 750;

  Person() {
    pos = new PVector(0, 0);
    equippedWeapon = null;
  }

  boolean isDead() {
    if (health <= 0) return true;
    return false;
  }

  int getRange() {
    int range = baseRange;
    if (equippedWeapon != null) range =  equippedWeapon.range;
    return range;
  }

  int getKnockback() {
    int distance = baseKnockback;
    if (this.equippedWeapon != null) distance = equippedWeapon.knockback;
    return distance;
  }

  int getDamage() {
    int dam = baseDamage;
    if (this.equippedWeapon != null) dam = equippedWeapon.damage;
    return dam;
  }

  int getCooldown() {
    int cooldown = baseCooldown;
    if (this.equippedWeapon != null) cooldown = equippedWeapon.cooldownTime;
    return cooldown;
  }

  boolean getIsLoud() {
    if (this.equippedWeapon != null) return equippedWeapon.isLoud;
    return false;
  }

  boolean hoveredOver(PVector mouse) {
    return dist(pos.x, pos.y, mouse.x, mouse.y) < size/2;
  }

  boolean isColliding() {
    // checks collisions with the four touching tiles
    Building curBuilding = buildings.get(whichBuilding);

    // if they're being knocked back, they use a different velocity
    // so figure out the velocity being used and change that
    PVector currVel = vel;
    if ((this instanceof NPC) && ((NPC)this).knockbackDistance != 0) currVel = ((NPC)this).knockbackVel;

    // create temporary variable storing the "next" position
    PVector nextPos = new PVector(pos.x + currVel.x, pos.y + currVel.y);

    // find your next square coords using next pos
    int c = int((nextPos.x - curBuilding.topCorner.x)/tSize);
    int r = int((nextPos.y - curBuilding.topCorner.y)/tSize);

    if (c < 0 || r < 0) return true;

    boolean hit = false;
    // then check the adjacent tiles
    if ((c+1 < curBuilding.cols) && (nextPos.x + size/2 > curBuilding.map[c+1][r].pos.x && curBuilding.map[c+1][r].solid) ||
      (c-1 >= 0) && (nextPos.x - size/2 + 1 < curBuilding.map[c-1][r].pos.x + tSize && curBuilding.map[c-1][r].solid)) {
      currVel.x = 0;
      hit = true;
    }
    if ((r+1 < curBuilding.rows) && (nextPos.y + size/2 > curBuilding.map[c][r+1].pos.y && curBuilding.map[c][r+1].solid) ||
      (r-1 >= 0) && (nextPos.y - size/2 + 1 < curBuilding.map[c][r-1].pos.y + tSize && curBuilding.map[c][r-1].solid)) {
      currVel.y = 0;
      hit = true;
    }

    if (hit && (this instanceof NPC)) {
      ((NPC)this).knockbackDistance = 0;
      return true;
    }

    // then check the close corner of the four tiles on the corners 
    float toCorner = 1000;
    PVector curCorner = new PVector(0, 0);

    int fC = -1;
    int fR = -1;

    // top right tile -> bottom left corner
    if ((c+1 < curBuilding.cols && r-1 >= 0) && curBuilding.map[c+1][r-1].solid) {
      curCorner.set(curBuilding.map[c+1][r-1].pos.x, curBuilding.map[c+1][r-1].pos.y + tSize);
      if (toCorner > dist(curCorner.x, curCorner.y, nextPos.x, nextPos.y)) {
        toCorner = dist(curCorner.x, curCorner.y, nextPos.x, nextPos.y);
        fC = c+1;
        fR = r-1;
      }
    }
    // bottom right tile -> top left corner
    if ((c+1 < curBuilding.cols && r+1 < curBuilding.rows) && curBuilding.map[c+1][r+1].solid) {
      curCorner.set(curBuilding.map[c+1][r+1].pos.x, curBuilding.map[c+1][r+1].pos.y);
      if (toCorner > dist(curCorner.x, curCorner.y, nextPos.x, nextPos.y)) {
        toCorner = dist(curCorner.x, curCorner.y, nextPos.x, nextPos.y);
        fC = c+1;
        fR = r+1;
      }
    }
    // bottom left tile -> top right corner
    if ((c-1 >= 0 && r+1 < curBuilding.rows) && curBuilding.map[c-1][r+1].solid) {
      curCorner.set(curBuilding.map[c-1][r+1].pos.x + tSize, curBuilding.map[c-1][r+1].pos.y);
      if (toCorner > dist(curCorner.x, curCorner.y, nextPos.x, nextPos.y)) {
        toCorner = dist(curCorner.x, curCorner.y, nextPos.x, nextPos.y);
        fC = c-1;
        fR = r+1;
      }
    }
    // top left tile -> bottom right corner
    if ((c-1 >= 0 && r-1 >= 0) && curBuilding.map[c-1][r-1].solid) {
      curCorner.set(curBuilding.map[c-1][r-1].pos.x + tSize, curBuilding.map[c-1][r-1].pos.y + tSize);
      if (toCorner > dist(curCorner.x, curCorner.y, nextPos.x, nextPos.y)) {
        toCorner = dist(curCorner.x, curCorner.y, nextPos.x, nextPos.y);
        fC = c-1;
        fR = r-1;
      }
    }

    if (toCorner < size/2-2) {    // if it found a close corner
      PVector fromCorner = new PVector(nextPos.x - (curBuilding.map[fC][fR].pos.x+tSize/2), nextPos.y - (curBuilding.map[fC][fR].pos.y + tSize/2));
      // fromCorner.set(nextPos.x - (curBuilding.map[fC][fR].x+tSize/2), nextPos.y - (curBuilding.map[fC][fR].y + tSize/2));
      currVel.set(fromCorner.x, fromCorner.y);
      currVel.normalize();
      pos.add(currVel);
      if (this instanceof NPC && ((NPC)this).target != null) ((NPC)this).updateVel();

      return true;
    }

    if (curBuilding.map[c][r].solid) return true;

    return false;
  }

  void genValidCoords() {
    Building genBuilding = buildings.get(whichBuilding);
    float tempX = random(genBuilding.topCorner.x+size/2, genBuilding.bottomCorner.x-size/2);
    float tempY = random(genBuilding.topCorner.y+size/2, genBuilding.bottomCorner.y-size/2);
    int tempC = int((tempX - genBuilding.topCorner.x)/tSize);
    int tempR = int((tempY - genBuilding.topCorner.y)/tSize);
    while (tempR>=genBuilding.rows || tempC>=genBuilding.cols || genBuilding.map[tempC][tempR].solid || 
      genBuilding.map[tempC][tempR].safe) {  // if you've generated a spot in a wall or safezone
      tempX = random(genBuilding.topCorner.x+size/2, genBuilding.bottomCorner.x-size/2);
      tempY = random(genBuilding.topCorner.y+size/2, genBuilding.bottomCorner.y-size/2);
      tempC = int((tempX - genBuilding.topCorner.x)/tSize);
      tempR = int((tempY - genBuilding.topCorner.y)/tSize);
    }
    this.pos.set(tempX, tempY);
    PVector toCenter = new PVector((genBuilding.map[tempC][tempR].pos.x + tSize/2) - pos.x, (genBuilding.map[tempC][tempR].pos.y+tSize/2) - pos.y);
    toCenter.normalize();
    while (this.isColliding ()) { // if you're colliding, you're gonna get moved closer to the center of the curr tile
      pos.add(toCenter);
    }
  }

  void genSafeCoords(Safezone zone) {
    Tile spawn = zone.spots[int(random(zone.spots.length))];
    float xpos = random(spawn.pos.x+size/2, spawn.pos.x+tSize-size/2);
    float ypos = random(spawn.pos.y+size/2, spawn.pos.y+tSize-size/2);
    this.pos.set(xpos, ypos);
  }

  void showMuzzleFlash() {
    pushMatrix();
    PVector toMouse = new PVector(mouseX + 50 - width/2, mouseY - height/2);
    translate(width/2-50, height/2);
    rotate(toMouse.heading());
    image(muzzleFlash, 23, 5, 30, 15);
    popMatrix();
  }

  abstract void update();
  abstract void display();
  abstract void attack();
  abstract void debugDisplay(boolean vision, boolean enemy, boolean pathline, boolean statedisplay);
}

class Player extends Person {
  PVector outsidePos; // used when entering buildings
  float hunger, morale, maxHunger = 100, maxMorale = 100;
  Item[] inventory = new Item[12];

  Player(float x, float y) {
    super();
    pos.set(x, y);

    // base stats 
    baseDamage = 50;
    baseRange = 25;
    baseKnockback = 100;
    baseCooldown = 750;

    // person variables
    health = 100;
    vel = new PVector(0, 0);
    speed = 2.75;

    outsidePos = new PVector(0, 0);
    hunger = 100;
    morale = random(25, 50) + random(25, 50);
    for (int i=0; i<inventory.length; i++) inventory[i] = null;
  }

  void update() {
    vel.set(0, 0);
    if (up) vel.y-=1;
    if (down) vel.y+=1;
    if (left) vel.x-=1;
    if (right) vel.x+=1;

    vel.normalize();
    vel.mult(speed);

    isColliding();

    pos.add(vel);
    pixelsTravelled += vel.mag();

    cooldown = max(cooldown - deltaTime, 0);  // can't go below 0;
    flashTimer = max(flashTimer - deltaTime, 0);
  }

  void display() {
    pushMatrix();
    resetMatrix();
    if (flashTimer > 0) showMuzzleFlash();
    popMatrix();
    fill(#1CEA32); 
    ellipse(pos.x, pos.y, size, size);
  }

  void attack() {
    if (cooldown == 0) {
      cooldown = this.getCooldown();
      int inRange = this.getRange();
      int dam = this.getDamage();
      boolean isLoud = this.getIsLoud();
      Weapon weapon = weapon = you.equippedWeapon;

      if (weapon != null && weapon.isRanged) shotsFired++;

      if (isLoud) {
        // play sound
        gunshot.rewind();
        gunshot.play();

        // show flash
        flashTimer = flashLength;

        // alert nearby zombies
        Zombie zombie;
        for (int i=0; i<current.zombies.size (); i++) {
          zombie = current.zombies.get(i);
          if (you.pos.dist(zombie.pos) < 300) zombie.behavior = chase;
        }
      } else {
        meleeSwing.rewind();
        meleeSwing.play();
      }

      Person[] hit = new Person[0];
      if (weapon != null) {
        hit = weapon.whatHit(mouse, this);
      } else {
        hit = hitOnLine(pos, mouse, inRange, this);
      }

      if (hit.length > 0) {
        if (!isLoud) {
          meleeHit.rewind();
          meleeHit.play();
          
        }
        for (Person temp : hit) {
          NPC entity = (NPC)temp; 
          if (weapon instanceof Throwable) {
            entity.knockedBack(((Throwable)weapon).explosionLocation(mouse, this), this.getKnockback());   // knock it back
          } else {
            entity.knockedBack(this);
          }
          entity.health-=dam*(1-entity.defense);  // damage it
          entity.behavior = chase;      // behavior change
          if (entity.isDead()) {     // then set kill stats
            if (entity instanceof Zombie) {
              zombiesKilled++;
            } else {
              peopleKilled++;
            }
            if (weapon != null) {
              weapon.kills++;
              favWeapon = findFavWeapon();
            }
          }
        }
      }
    }
  }

  void debugDisplay(boolean vision, boolean enemy, boolean pathline, boolean statedisplay) {
    if (equippedWeapon != null) equippedWeapon.debugDisplay();
  }

  boolean getItem(int item) {
    // gives an item. if it's not lore, it generates a new copy of the item
    // and then gives it through getItem(Item)
    Item recieve = null;
    if (item != -1) recieve = items.get(item);

    if (recieve == lore) {  // if they found a lore item (this is checking the reference, as lore is an object)
      journal.addPage(storyline[journal.pages.size()-1]);
      return true;
    }

    Item copy;
    if (recieve != null) {
      copy = recieve.clone();
      copy.ran = randint(100);
      return getItem(copy);
    } else {
      return false;
    }
  }

  boolean getItem(Item item) {
    // gives a unique item to player
    for (int i=0; i<inventory.length; i++) {
      if (inventory[i] == null) {
        inventory[i] = item;
        return true;
      }
    }
    return false;
  }

  void craft(IntList spots, Recipe curr) {
    // takes the spots of inventory and the crafting recipe and crafts it
    if (curr != null) {   // failsafe for non existant recipes
      for (int i : spots) {
        you.inventory[i] = null;    // clear inv spots from crafting components
      }
      this.getItem(curr.result);   // give the result
      Item temp = items.get(curr.result);
      String itemName = indefiniteArticle(temp.name.toLowerCase()) + temp.name.toLowerCase();
      console("You crafted " + itemName + ".");
      itemsCrafted++;
    }
  }
}

abstract class NPC extends Person {
  int awareness;   // how far they can see you from
  Behavior behavior;
  Behavior nextBehavior; // for if NPC is in GoTo state
  PVector[] target;
  int currentTarget;
  Person enemy;
  float knockbackDistance = 0;
  PVector knockbackVel;
  final float knockbackSpeed = 4;
  float defense;
  float regularSpeed;
  ArrayList<? extends NPC> list;  // the list that this belongs to

  NPC(ArrayList<? extends NPC> inList) {
    // call the Person constructor
    super();

    // save which list this belongs to
    list = inList;

    // randomize direction
    vel = new PVector(random(-1, 1), random(-1, 1));
    
    // base values for NPCs
    awareness = 200;
    behavior = null;
    target = null;
    currentTarget = 0;

    enemy = null;
    knockbackVel = new PVector(0, 0);
  }

  void setBehavior(Behavior b) {
    // sets the behavior of the NPC, and resets the counter
    currentTarget = 0;
    behavior = b;
    behavior.newTarget(this);
    updateVel();
  }

  void goToTarget(PVector t, Behavior after) {
    // sets the target location for the NPC, and
    // what behavior they will do when they get there
    nextBehavior = after;

    currentTarget = 0;
    target = new PVector[1];
    target[0] = t.get();
     
    setBehavior(totarg);
  }

  void update() {
    if (!isDead()) {  // alive
      if (random(1) < .05 && hasVisibilityLine(pos, target[currentTarget])) updateVel();   // this is to reset zeroed velocities by collision

      if (isColliding()) behavior.collide(this);  // to prevent running into walls

        // random comment to fix formatting
      if (knockbackDistance == 0) {
        pos.add(vel);
      } else {
        pos.add(knockbackVel);
        knockbackDistance = max(knockbackDistance - knockbackVel.mag(), 0);
      }

      if (target != null && pos.dist(target[currentTarget]) < size/4) {  // arrived at target
        if (currentTarget < target.length-1) {  // there's another target available
          currentTarget++;
          updateVel();
        } else {  // at the end of the list
          currentTarget = 0;
          behavior.doneList(this);
          updateVel();
        }
      }

      stateManager();

      behavior.update(this);
    } else { // dead
      // stop sound from playing

      // tell their safezone they've died, janky fix
      if(this instanceof Survivor) {
        Survivor s = (Survivor)this;
        if(s.territory != null) {  // they're from a safezone
          s.territory.registerDeath(s);
        }
      }

      // remove self from the list that they are in
      list.remove(this);
    }
  }

  boolean canSee(Person p) {

    // first check the distance
    if (p.pos.dist(this.pos) > this.awareness) return false; 

    // if they're moving, using vel heading
    if (vel.mag() != 0) {
      float angle;
      PVector toTarg = p.pos.get();

      toTarg.sub(this.pos);
      angle = PVector.angleBetween(toTarg, this.vel);

      // if they're not facing you, false
      if (angle > visionAngle/2) return false;

      // if not, false

        if (!hasVisibilityLine(pos, p.pos)) return false;

      return true;
    } 

    if (!hasVisibilityLine(pos, p.pos)) return false;

    // at this point they're standing still and you're in their awareness
    // zone, so assuming full "vision" when still allows them to see you
    return true;
  }

  void updateVel() {
    vel.set(target[currentTarget].x - pos.x, target[currentTarget].y - pos.y);
    vel.normalize();
    vel.setMag(speed);
    
  }

  void knockedBack(Person hitter) {
    this.knockedBack(hitter.pos, hitter.getKnockback());
  } 

  void knockedBack(PVector hitFrom, int distance) {
    // sets the knocked back zombie's target in the direction of hit

    final float kBVariation = 0.2;

    // first, creates a vector from this to hitter
    PVector toHitter = hitFrom.get();
    toHitter.sub(this.pos);
    // then flip it
    PVector knockback = new PVector(-toHitter.x, -toHitter.y);
    if (distance < 0) knockback.mult(-1);
    PVector newTarg = new PVector(this.pos.x, this.pos.y);
    newTarg.add(knockback);

    knockbackVel.set(newTarg.x  + random(-10, 10) - pos.x, newTarg.y  + random(-10, 10) - pos.y);
    knockbackVel.setMag(knockbackSpeed);

    knockbackDistance = abs(distance) * (1.0 + (random(-kBVariation, kBVariation)));
  }

  void debugDisplay(boolean vision, boolean enemyline, boolean pathline, boolean statedisplay) {
    pushStyle();

    stroke(#CB1010);
    if (enemyline && enemy != null) line(pos.x, pos.y, enemy.pos.x, enemy.pos.y);

    fill(#0F6CDB);
    stroke(#0F6CDB);
    if (pathline && target != null) {
      for (int i=currentTarget+1; i<target.length; i++) {
        // ellipse(target[i].x, target[i].y, 5, 5);
        line(target[i-1].x, target[i-1].y, target[i].x, target[i].y);
      }
      fill(#0FA6DB);
      stroke(#0FA6DB);
      ellipse(target[currentTarget].x, target[currentTarget].y, 5, 5);
      line(pos.x, pos.y, target[currentTarget].x, target[currentTarget].y);
    }

    if (vision && enemy == null) {
      noFill();
      stroke(#FFFFFF);
      float direction = vel.heading();
      // ellipse(pos.x, pos.y, awareness*2, awareness*2);
      if (vel.mag() > 0) arc(pos.x, pos.y, awareness*2, awareness*2, direction-visionAngle/2, direction+visionAngle/2, PIE);
      ellipse(pos, awareness*2);
    }

    if (statedisplay) {
      textAlign(CENTER, TOP);
      textSize(12);
      fill(#FFFFFF);
      text(behavior.name, pos.x, pos.y+10);
    }

    popStyle();
  }  

  abstract void display();
  abstract void stateManager();
}

class Zombie extends NPC {

  Zombie(int buildingID, ArrayList<Zombie> list) {
    super(list);
    baseDamage = 10;
    baseRange = 20;
    baseKnockback = 0;
    baseCooldown = 750;

    speed = random(.25, 1.0) + random(.25, 1.0);  // between 0.5 and 2.0, highest chance for 1.25
    health = (1.25/speed) * 100;

    whichBuilding = buildingID;

    regularSpeed = speed;
    speed = regularSpeed/2;

    genValidCoords();

    behavior = wander;
    behavior.newTarget(this);
  }

  Zombie(int buildingID, PVector mousePos, Behavior bhv) {
    this(buildingID, buildings.get(buildingID).zombies);
    pos = mousePos.get();
    behavior = bhv;
    behavior.newTarget(this);
  }

  void update() {
    super.update();
  }

  void display() {
    fill(#000000);
    if (tagged) fill(#CBE817);
    ellipse(pos.x, pos.y, size, size);
  }


  void stateManager() {
    ArrayList<Person> entities = allHostiles(this);

    for (Person p : entities) {
      if (this.canSee(p)) {
        setBehavior(chase);
        break;
      }
    }
  }

  void transform() {
  }

  void attack() {
  }
}

abstract class Survivor extends NPC {
  Safezone territory;
  boolean guarding;

  Survivor(int buildingID, ArrayList<Survivor> list) {
    super(list);
    baseDamage = 50;
    baseRange = 25;
    baseKnockback = 100;
    baseCooldown = 750;

    // person variables
    health = 100;
    vel = new PVector(random(-1, 1), random(-1, 1));
    speed = random(.25, 1.0) + random(.25, 1.0);  // between 0.5 and 2.0, highest chance for 1.25
    health = (1.25/speed) * 100;

    whichBuilding = buildingID;

    regularSpeed = speed;
    speed = 1;

    genValidCoords();
    
    guarding = false;

    behavior = wait;
    behavior.newTarget(this);
  }

  Survivor(int buildingID, PVector mousePos, Behavior bhv) {
    this(buildingID, buildings.get(buildingID).survivors);
    pos = mousePos.get();
    behavior = bhv;
    behavior.newTarget(this);
  }

  Survivor(int buildingID, Safezone home) {
    this(buildingID, home.survivors);
    territory = home;
    genSafeCoords(territory);
  }

  void update() {
        
    if(territory != null && !guarding && territory.needsGuard()) {
      territory.acceptGuard(this);
    }
    
    super.update();
  }

  void display() {
    fill(#D128C9);
    if (tagged) fill(#CBE817);
    ellipse(pos.x, pos.y, size, size);
  }

  void stateManager() {
    ArrayList<Person> list = allHostiles(this);

    for (Person p: list) {
      if (canSee(p)) {
        setBehavior(flee);
      }
    }
  }
}

class Civilian extends Survivor {
  Civilian(int buildingID) {  // survivor without safezone, roamer
    super(buildingID, buildings.get(buildingID).survivors);
  }

  Civilian(int buildingID, PVector mouse, Behavior bhv) {  // clicking to spawn, debugging
    super(buildingID, mouse, bhv);
  }

  Civilian(int buildingID, Safezone zone) {  // survivors being added to safezones 
    super(buildingID, zone);
  }

  void stateManager() {
    super.stateManager();
  }

  void attack() {
  }
}

