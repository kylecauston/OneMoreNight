
ArrayList<Safezone> safezones;  // list of safe areas to spawn in

class Safezone {
  Tile[] spots;
  Tile[] openings;
  boolean[] guarded;
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
    guarded = new boolean[currentOpenings.size()];

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
    if (c>=0 && r>=0 && c<current.cols && r<current.rows && !current.map[c][r].solid && !current.map[c][r].tagged) {
      Tile tile = current.map[c][r]; 
      tile.tagged = true; 
      if (tile.safe) {
        currentZone.add(tile); 
        modifiedFloodFill(r+1, c, currentZone, currentOpenings); 
        modifiedFloodFill(r-1, c, currentZone, currentOpenings); 
        modifiedFloodFill(r, c+1, currentZone, currentOpenings); 
        modifiedFloodFill(r, c-1, currentZone, currentOpenings); 
        return true;
      } else {  // not safe, and not solid
        currentOpenings.add(tile); 
        return false;
      }
    } else {
      return false;
    }
  }

  void addSurvivors(int num) {
    // add survivors to this safezone
    for (int i=0; i<num; i++) this.survivors.add(new Civilian(0, this));   // safezones are only outside (outside.ID == 0)
  }
}

void loadSafezones() {
  safezones = new ArrayList<Safezone>();
  Tile temp;
  for (int c=0; c<current.cols; c++) {
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
  }
}

