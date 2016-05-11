
class Menu<T> {
  // creates interactive menu for state changing
  final int textHeight = 25;
  final int dim = 75;
  PVector position;
  boolean centered;    // on x axis
  T[] choices;
  String[] labels;
  PFont font;

  Menu(float x, float y, boolean cent) { 
    font = loadFont("Fonts/SansSerif-20.vlw");
    position = new PVector(x, y);
    centered = cent;
    choices =(T[])new Object[0];
    labels = new String[0];
  }

  void add(String inTitle, T inOption) {
    labels = append(labels, inTitle);
    choices = (T[])append(choices, inOption);
  }

  T choose() {
    int currChoice = floor(constrain((mouseY-position.y)/textHeight, 0, choices.length-1));
    return choose(currChoice);
  }

  T choose(int pick) {
    return choices[pick];
  }

  void display() {
    textFont(font);
    textSize(18);
    textAlign(CENTER, TOP);
    if (!centered) textAlign(LEFT, TOP);

    int currChoice = floor(constrain((mouseY-position.y)/textHeight, 0, labels.length-1));     

    for (int i=0; i<labels.length; i++) {
      fill(#FFFFFF);
      if (i!=currChoice) fill(#FFFFFF, dim);
      text(labels[i], position.x, position.y + textHeight*i);
    }
  }
}

