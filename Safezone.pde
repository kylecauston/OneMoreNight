
ArrayList<Safezone> safezones;  // list of safe areas to spawn in

class Safezone {
  Tile[] spots;
  Tile[] openings;
  Survivor[] guards;  // flag to tell survivors to try guarding
  int numGuards;

  PVector centerpoint;
  PVector topLeft, bottomRight;
  ArrayList<Survivor> survivors;

  Safezone(int r, int c) {
    ArrayList<GridTile> currentZone = new ArrayList<GridTile>();
    ArrayList<GridTile> currentOpenings = new ArrayList<GridTile>();

    modifiedFloodFill(r, c, currentZone, currentOpenings);

    spots = new Tile[currentZone.size()];
    spots = currentZone.toArray(spots);
    openings = new Tile[currentOpenings.size()];
    openings = currentOpenings.toArray(openings);
    guards = new Survivor[currentOpenings.size()];
    for (int i=0; i<guards.length; i++) guards[i] = null;

    numGuards = 0;

    calcCenter();

    survivors = new ArrayList<Survivor>();
  }

  private void calcCenter() {
    // assuming rectangular shape
    //  find topR and botopLeft corners
    topLeft = spots[0].pos.get();
    bottomRight = (spots[0].pos.get());
    bottomRight.set(bottomRight.x+tSize, bottomRight.y+tSize);
    for (Tile temp : spots) {
      if (temp.pos.x + tSize > bottomRight.x) bottomRight.x = temp.pos.x+tSize;  // more right than current right
      if (temp.pos.x < topLeft.x) topLeft.x = temp.pos.x; // more left than current left
      if (temp.pos.y + tSize > bottomRight.y) bottomRight.y = temp.pos.y+tSize;
      if (temp.pos.y < topLeft.y) topLeft.y = temp.pos.y;
    }

    // given the corners, we can calculate the width and height
    float h = bottomRight.y - topLeft.y;
    float w = bottomRight.x - topLeft.x;
    centerpoint = new PVector(topLeft.x + round(w/2), topLeft.y+round(h/2));
  }

  private boolean modifiedFloodFill(int r, int c, ArrayList<GridTile> currentZone, ArrayList<GridTile> currentOpenings) {
    // recursive flood fill, keeps track of safe tiles + "openings" (non solid, non safe, connected tiles)

    // bounds checking
    if (c<0 || r<0 || c>=current.cols || r>=current.rows || current.map[c][r].solid || current.map[c][r].tagged) {
      return false;
    }

    Tile tile = current.map[c][r]; 
    tile.tagged = true; 

    // if it's not a safe tile, don't keep expanding
    if (!tile.safe) {
      currentOpenings.add(tile); 
      return false;
    }

    currentZone.add(tile); 
    modifiedFloodFill(r+1, c, currentZone, currentOpenings); 
    modifiedFloodFill(r-1, c, currentZone, currentOpenings); 
    modifiedFloodFill(r, c+1, currentZone, currentOpenings); 
    modifiedFloodFill(r, c-1, currentZone, currentOpenings); 
    return true;
  }

  boolean needsGuard() { return (openings.length > numGuards); }

  void addSurvivors(int num) {
    // add survivors to this safezone
    for (int i=0; i<num; i++) this.survivors.add(new Civilian(0, this));   // safezones are only outside (outside.ID == 0)
  }

  void registerDeath(Survivor s) {
    // essentially just used to check if a guard has died

    for (int i=0; i<openings.length; i++) {
      if (guards[i] == s) {  // the dying survivor was a guard
        // remove him from guard list, since he's dying
        guards[i] = null;
        numGuards--;
        break;
      }
    }
  }

  boolean acceptGuard(Survivor g) {
    //   Takes g as a new guard, gives them an opening
    // to defend, saves them and sends them to their 
    // new post. 
    //   If no openings, ???

    for (int i=0; i<openings.length; i++) {
      if (guards[i] == null) {  // found a post to guard
          g.guarding = true;
          numGuards++;
          guards[i] = g;
          g.goToTarget(openings[i].pos, wait);
          break;
        
      }
    }

    return false;
  }
}

void loadSafezones() {
  safezones = new ArrayList<Safezone>();
  Tile temp;
  for (int c  =0; c<current.cols; c++) {
    for (int r=0; r<current.rows; r++) {
      temp = current.map[c][r];
      if (!temp.tagged && temp.safe) {
        safezones.add(new Safezone(r, c));
      }
    }
  }

  for (Safezone zone : safezones) {
    for (int i=0; i<zone.spots.length; i++) zone.spots[i].tagged = false;
    for (int i=0; i<zone.openings.length; i++) zone.openings[i].tagged = false;

    zone.addSurvivors(zone.openings.length + 3);

    //for (Survivor s : zone.survivors) {
     // zone.acceptGuard(s);
    //}
  }
}

