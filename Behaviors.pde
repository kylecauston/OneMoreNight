Behavior wander;
Behavior chase;
Behavior totarg;
Behavior wait;
Behavior flee;

abstract class Behavior {
  // behaviors for NPC's
  
  String name;
  
  // dictates when to update targets
  abstract void update(NPC current);
  
  // deals with what happens when NPC hits a wall or something
  // normally nothing
  abstract void collide(NPC current);
  
  // how a new target is generated
  abstract void newTarget(NPC current);
  
  // what to do when the NPC has reached the last target
  abstract void doneList(NPC current);
}

class Wander extends Behavior {
  // the wander behavior works by taking the current direction vector,
  // setting it's magnitude to 100, and then randomizing it. This new
  // point becomes the NPC's target. Since collisions set the direction
  // parallel with the wall, wandering works even when walking into walls
  
  Wander() {
    name = "Wander";
  }

  void update(NPC current) {
    if (random(1) < .025) {
      this.newTarget(current);   // 2.5% of time, update target
      current.updateVel();
    }
  }

  void collide(NPC current) {
    if (random(1) < .25) this.newTarget(current);
  }

  void newTarget(NPC current) {
    PVector wander = new PVector(current.vel.x, current.vel.y);
    wander.setMag(100);  // go ahead 100px
    wander.x += random(-50, 50);  // randomize
    wander.y += random(-50, 50);

    PVector[] array = new PVector[1];
    array[0] = new PVector(current.pos.x+wander.x, current.pos.y+wander.y);
    current.target = array;
  }

  void doneList(NPC current) {
    newTarget(current);
  }
}

class Chase extends Behavior {
  // chase is a simple behavior. 
  // it simply gets the position of it's enemy, randomizes it 
  // a little bit, and then adds it to the target. 
  // Maybe, have a more complex chase that uses the pathfinder.
  
  Chase() {
    name = "Chase";
  }

  void update(NPC current) {
    if (current.speed >= 1) current.speed = current.regularSpeed;
    if (random(1) < .025) current.enemy = closestEnemy(current);
    if (random(1) < .025) this.newTarget(current);
  }

  void collide(NPC current) {
  }

  void newTarget(NPC current) {
    if (current.enemy == null) current.enemy = closestEnemy(current);

    PVector[] array = new PVector[1];
    array[0] = current.enemy.pos.get();
    array[0].add(new PVector(random(-20, 20), random(-20, 20)));
    current.target = array;
  }

  void doneList(NPC current) {
    newTarget(current);
  }
}

class GoTo extends Behavior {
  /* 
      The GoTo behavior is somewhat complex to use, regrettably.
    NPC can't be set to GoTo by itself, it needs to be set using
    the goToTarget() method in NPC. This is because you need to
    specify two things:
      1) Target location
      2) Behavior once at location
    This function assumes those have been set.
  
      The actual mechanics are ezpz -- it just takes the end of
    the target array (the last target, the location desired), and
    calls the pathfinder with it.
  */
  
  GoTo() {
    name = "GoTo";
  }

  void update(NPC current) {
  }

  void collide(NPC current) {
    // chance to create new path to same target
    if (random(1) < .025) newTarget(current);
  }

  void newTarget(NPC npc) {
    PVector[] array;

    // if this is the first time this has been called, target[length-1] is only going to contain the new target
    // if this is being called from update/collide, target[length-1] is going to be the endpoint
    array = GridMath.path_dfs(current.map, current.rows, current.cols, npc.pos, npc.target[npc.target.length-1]);
    array = GridMath.pathShortener(array, current.map);

    npc.target = array;
  }

  void doneList(NPC current) {
    current.setBehavior(current.nextBehavior);
  }
}

class Wait extends Behavior {
  // extrodinarily simple behavior. Why are you even looking at this comment!?
  
  Wait() {
    name = "Wait";
  }

  void update(NPC current) {
    current.vel.set(0, 0);
  }

  void collide(NPC current) {
  }

  void newTarget(NPC current) {
    PVector[] array = new PVector[1];
    array[0] = current.pos;
    
    current.target = array;
  }

  void doneList(NPC current) {
  }
}

class Flee extends Behavior {
  /* 
      The opposite of chase. Takes the vector to the target,
    gets the opposite vector (vector away from target), and
    then applies a bit of randomness (as both wander and 
    chase have).
      Need to add a time-out for flee, causing it to end. 
    Either time, distance or line of sight. Maybe all three.
  */
  
  Flee() {
    name = "Flee";
  }

  void update(NPC current) {
    current.speed = current.regularSpeed;
    if (random(1) < 0.01) current.enemy = closestEnemy(current);
    if (random(1) < 0.05) this.newTarget(current);
  }

  void collide(NPC current) {
  }

  void newTarget(NPC current) {
    if (current.enemy == null) current.enemy = closestEnemy(current);

    PVector[] array = new PVector[1];
    array[0] = current.pos.get();
    array[0].sub(current.enemy.pos.get());
    array[0].setMag(100);
    array[0].add(current.pos.get());
    array[0].add(new PVector(random(-5, 5), random(-5, 5)));
    current.target = array;
  }

  void doneList(NPC current) {
    newTarget(current);
  }
}

