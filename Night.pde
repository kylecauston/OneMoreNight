// timer and night attack calculations

// day/night cycle code
final int dayLength = 300 * 1000;//75 * 1000; //first number is the actual number of seconds
boolean day = true;
int time;
float countdown;
int deltaTime;
boolean nightWarning = true;

int timeDay = 0;
int timeMinutes = 0;
int timeSeconds = 0;

void timer() {  
  if (countdown <= 0) {    // day is over
    if (nightWarning && current.ID == 0) { 
      console("\"I should really get inside... it's getting dark out.\"");
      nightWarning = false;
    }
    day = false;
    for (Zombie zombie : buildings.get (0).zombies) {
      zombie.transform();
    }
  }
}

// bad coding to put variables down here... just trust me it'll be okay

// night time happenings
final float zombieSpeedMultiplier = 1.5;  // x% faster (1.x)
final float zombieToughness = 0.35;   // defend x% of damage (0.x)

float screenFade = 0;
int pauseTime = 0;
boolean goToSleep = false;
boolean wakeUp = false;

int attackingZombies;  // how many attacked that night
int minZombies, maxZombies;

int calcNightlyAttack(int night) {
  minZombies = int(pow(night, 2) - 3*night + 5);  // equation for zombies
  maxZombies = minZombies*2;
  return round(random(minZombies, maxZombies));
}

int calcNightlyDamages() { 
  return round(float(attackingZombies)/2.0);
}

void sleep(int night) {
  // triggers the night attack
  attackingZombies = calcNightlyAttack(night);    // gen zombies

  int numZombiesIn = max(0, attackingZombies - current.def);  // how many zombies get in the building
  int moraleNeeded = numZombiesIn*2;    // it takes 2% morale to fight off one zombie

  you.morale-= moraleNeeded;
  if (you.morale < 0) {  // dies
    deathReason = "Zombies got in, and you just couldn't take it any longer.";
    state = deadtest;
  }

  current.takeDamage(calcNightlyDamages());    // damage the building

  // print the report
  String nightReport = attackingZombies + " zombies attacked, ";
  if (numZombiesIn > 0) nightReport += numZombiesIn + " got in, "; 
  nightReport += "and " + calcNightlyDamages() + " defense was lost during the night's attack.";

  console(nightReport);

  // add zombies outside
  buildings.get(0).fillWithZombies(15); 

  // update/grow any interacted items
  for (Building b : buildings) {
    for (Furnishing f : b.furnishings) {
      if (f == null) continue;
      if (f instanceof Harvest && ((Harvest)f).interactedWith) ((Harvest)f).age++;
      f.interactedWith = false;
    }
  }

  for (Item i : you.inventory) {
    if (i instanceof Furnishing) ((Furnishing)i).interactedWith = false;
  }
}

