
/* 
 Contains:
 
 - LootTable
 - GridMath
 */

class LootTable<T> {
  float[] chances;  // must add up to 1
  T[] output;

  LootTable(float[] percents, T[] input) {
    chances = new float[percents.length];
    output = (T[])new Object[chances.length];

    for (int i=0; i<output.length; i++) output[i] = input[i];

    for (int i=0; i<chances.length; i++) {
      chances[i] = percents[i];
      for (int j=i-1; j>=0; j--) {
        chances[i] += percents[j];
      }
    }
    if (chances[chances.length-1] != 1) println("Warning: Loot table chances do not total to 1. Total is: " + chances[chances.length-1] + ".");
  }

  T generate() {
    float value = random(1);
    for (int i=0; i<chances.length; i++) {
      if (value<=chances[i]) {
        return output[i];
      }
    }
    return null;
  }
}

static class GridMath {
  // static class used for generating paths and designing shapes on grids
  static void clearMap(GridTile[][] grid, int numRows, int numCols) {
    for (int r=0; r<numRows; r++) {
      for (int c=0; c<numCols; c++) {
        grid[c][r].tagged = false;
      }
    }
  }

  static PVector[] path_dfs(GridTile[][] grid, int numRows, int numCols, PVector start, PVector finish) {
    int size = grid[0][0].size;
    int startCol = floor(start.x/size);
    int startRow = floor(start.y/size);
    int endCol = floor(finish.x/size);
    int endRow = floor(finish.y/size);

    // ensure the start and end are in bounds
    if (startCol < 0 || startRow < 0 || endCol < 0 || endRow < 0
      || startCol >= numCols || startRow >= numRows  
      || endCol >= numCols || endRow >= numRows) {
      println("Target is out of bounds.");
      return null;
    }

    // don't keep going if it's a solid tile
    if (grid[endCol][endRow].solid) {
      println("Target is in solid tile, could not reach.");
      return null;
    }
    
    ArrayList<GridTile> path = new ArrayList<GridTile>();
    dfs_recursive(startRow, startCol, grid[endCol][endRow], grid, path, numRows, numCols);

    ArrayList<PVector> locations = new ArrayList<PVector>();
    PVector center;
    for (GridTile temp : path) {
      temp.tagged = false;

      center = temp.pos.get();
      center.set(center.x + temp.size/2, center.y + temp.size/2);
      locations.add(center);
    }

    PVector[] array = new PVector[locations.size()];
    array = locations.toArray(array);

    return array;
  }

  static private boolean dfs_recursive(int r, int c, GridTile target, GridTile[][] grid, ArrayList<GridTile> path, int numRows, int numCols) {
    if (r>=numRows || c>=numCols || r < 0 || c < 0 || grid[c][r].solid || grid[c][r].tagged) return false;

    path.add(grid[c][r]);
    grid[c][r].tagged = true;
    if (grid[c][r] == target) {  // if you're at the end
      return true;
    } else {    // or else continue 
      PVector[] h = heuristic(r, c, grid[c][r], target);
      if (dfs_recursive(r+round(h[0].y), c+round(h[0].x), target, grid, path, numRows, numCols) ||
        dfs_recursive(r+round(h[1].y), c+round(h[1].x), target, grid, path, numRows, numCols) ||
        dfs_recursive(r+round(h[2].y), c+round(h[2].x), target, grid, path, numRows, numCols) ||
        dfs_recursive(r+round(h[3].y), c+round(h[3].x), target, grid, path, numRows, numCols)) {
        return true;  // if it has found the target, stop looking
      }
    }
    path.remove(grid[c][r]);
    return false;
  }

  static private PVector[] heuristic(int r, int c, GridTile curTile, GridTile target) {
    // returns the priority array of directions from current spot
    PVector[] array = new PVector[4];
    PVector up = new PVector(0, -1);
    PVector down = new PVector(0, 1);
    PVector left = new PVector(-1, 0);
    PVector right = new PVector(1, 0);

    int size = curTile.size;
    PVector toTarget = new PVector((target.pos.x + size/2) - (curTile.pos.x + size/2), (target.pos.y + size/2) - (curTile.pos.y + size/2));

    if (abs(toTarget.x) > abs(toTarget.y)) {
      // x axis priority
      if (toTarget.x > 0) {
        // target is to the right (positive x)
        array[0] = right;
        array[3] = left; // most definiatly not to the left
      } else { // x <= 0, or left
        array[0] = left;
        array[3] = right;
      }
      if (toTarget.y > 0) {
        // target is down (positive y)
        array[1] = down;
        array[2] = up;   // opposite of down, least priority
      } else {   // y <= 0, or up
        array[1] = up;
        array[2] = down;
      }
    } else { // x<=y, or vertical priority
      if (toTarget.y > 0) {
        // target is down (positive y)
        array[0] = down;
        array[3] = up;   // opposite of down, least priority
      } else {   // y <= 0, or up
        array[0] = up;
        array[3] = down;
      }
      if (toTarget.x > 0) {
        // target is to the right (positive x)
        array[1] = right;
        array[2] = left; // most definiatly not to the left
      } else { // x <= 0, or left
        array[1] = left;
        array[2] = right;
      }
    }

    return array;
  }

  static PVector[] path_bfs() {
    return null;
  }

  static PVector[] path_AStar() {
    return null;
  }

  static PVector[] pathShortener(PVector[] path, GridTile[][] grid) {   // private?
    if (path != null && path.length > 0) {
      boolean found = false;
      int spot = 0;
      PVector current = path[0];
      ArrayList<PVector> quickpath = new ArrayList<PVector>();
      quickpath.add(current);

      while (current!= path[path.length-1]) {    // until the end
        for (int p=path.length-1; p>spot; p--) {  // look at the last one, and work backwards
          if (clearPath(current, path[p], grid) && !quickpath.contains(path[p])) {
            quickpath.add(path[p]);
            current = path[p];
            spot = p;
            found = true;
            break;
          }
        }
        if (!found) {
          quickpath.add(current);
          spot++;
          current = path[spot];
          found = false;
        }
      }

      PVector[] array = new PVector[quickpath.size()];
      for (int i=0; i<quickpath.size (); i++) array[i] = quickpath.get(i);

      return array;
    } else {
      return null;
    }
  }

  static private boolean clearPath(PVector start, PVector target, GridTile[][] grid) {
    PVector step = target.get();
    step.sub(start);
    step.setMag(3);
    PVector curPos = start.get();

    int numSteps = ceil(start.dist(target)/step.mag());

    int size = grid[0][0].size;

    int c, r;

    for (int s=0; s<numSteps; s++) {
      curPos.add(step);

      c = int(curPos.x/size);
      r = int(curPos.y/size);

      if (grid[c][r].solid) return false;    // if it hits a wall, end
    }
    return true;
  }

  static ArrayList<GridTile> flood_fill(int r, int c, GridTile[][] grid, int numRows, int numCols) {
    ArrayList<GridTile> tiles = new ArrayList<GridTile>();
    fill_recursive(r, c, grid, tiles, numRows, numCols);
    for (GridTile temp : tiles) temp.tagged = false;
    return tiles;
  }

  static private boolean fill_recursive(int r, int c, GridTile[][] grid, ArrayList<GridTile> allTiles, int numRows, int numCols) {
    if (r<numRows && c<numCols && r>=0 && c>=0 && !grid[c][r].tagged && !grid[c][r].solid) {
      grid[c][r].tagged = true;
      allTiles.add(grid[c][r]);
      fill_recursive(r+1, c, grid, allTiles, numRows, numCols);
      fill_recursive(r-1, c, grid, allTiles, numRows, numCols);
      fill_recursive(r, c+1, grid, allTiles, numRows, numCols);
      fill_recursive(r, c-1, grid, allTiles, numRows, numCols);
      return true;
    }
    return false;
  }

  static void bresenham_line() {
  }

  static void bresenham_circle() {
  }
}

