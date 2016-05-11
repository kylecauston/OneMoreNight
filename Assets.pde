// assets and small classes

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import java.util.Map;    // hashmaps

PFont clock;
PFont plain;
PFont dayFont;
PFont titleFont;
PFont defaultFont;
PFont creditFont;

String [] credits;

// fuck these variables I'm not taking the time to fix this stuff rn
int grass;
int textYPos;
PVector target;
TitleZombie[] titleHorde = new TitleZombie[15];
Drop[] rain = new Drop[500];
PImage house;
PImage steak;
PFont titleScreenFont;
int opacity = 0;

Minim minim;
AudioPlayer[] zombieMoans, zombieGrowls, nightBanging;
AudioPlayer nextPageSound, prevPageSound;
AudioPlayer meleeSwing, gunshot;
AudioPlayer meleeHit;
AudioPlayer theme, song;

PImage controls;
PImage title;
PImage gameover;
PImage muzzleFlash;
PImage sleepingBag;
PImage survivor;
PImage zLeft;
PImage zRight;
PImage[] campfire = new PImage [6];

HashMap<String, PImage> tileMap = new HashMap<String, PImage>();
HashMap<String, Float> newLoadTimeTotals_map = new HashMap<String, Float>();
HashMap<String, Float> oldLoadTimeAverage = new HashMap<String, Float>();

void setupAss() {
  //FONTS
  plain = loadFont("Fonts/SansSerif-20.vlw");
  clock = loadFont("Fonts/LetsgoDigital-Regular-48.vlw");
  dayFont = loadFont("Fonts/WantedM54-40.vlw");
  creditFont = loadFont("TitleScreen/Chiller-Regular-48.vlw");

  credits = loadStrings("credits.txt");

  minim = new Minim(this);

  zombieMoans = loadManySounds("Sounds/moan");
  zombieGrowls = loadManySounds("Sounds/growl");
  nightBanging = loadManySounds("Sounds/night");

  nextPageSound = minim.loadFile("Sounds/pageNext.mp3");
  prevPageSound = minim.loadFile("Sounds/pagePrev.mp3");
  meleeSwing = minim.loadFile("Sounds/swing.mp3");
  meleeHit = minim.loadFile("Sounds/hit.mp3");
  gunshot = minim.loadFile("Sounds/gunshot.mp3");

  theme = minim.loadFile("DeepHaze.mp3");

  for (int i=0; i<campfire.length; i++) {
    campfire[i] = loadImage("TitleScreen/campfire/frame_00" + i + ".png");
  }
  house = loadImage("TitleScreen/myHouse.png");
  steak = loadImage("TitleScreen/steak.png");
  zLeft = loadImage("TitleScreen/Zleft.png");
  zRight = loadImage("TitleScreen/Zright.png");
  survivor = loadImage("TitleScreen/survivor at fire.png");
  muzzleFlash = loadImage("flash.png");
  controls = loadImage("controls.png");
  title = loadImage("Title.png");
  gameover = loadImage("gameover.png");
  sleepingBag = loadImage("Sleeping Bag.png");

  //IMAGES
  // three keys used to load in the human readable tile names
  String[] buildKey;
  String[] tileKey;
  String[] variantKey;
  PImage temp;
  buildKey = loadStrings("Tiles/buildingKey.txt");
  for (int b=0; b<buildKey.length; b++) {
    tileKey = loadStrings("Tiles/" + buildKey[b] + "/tileKey.txt");
    for (int t=0; t<tileKey.length; t++) {
      variantKey = loadStrings("Tiles/" +buildKey[b] + "/" + tileKey[t] + "/variantKey.txt");
      for (int v=0; v<variantKey.length; v++) {
        temp = loadImage("Tiles/" + buildKey[b] + "/" + tileKey[t] + "/" + variantKey[v] + ".png");
        tileMap.put((str(b) + str(t) + str(v)), temp);
      }
    }
  }
}

class TitleZombie {
  float x, y;
  PVector vel;
  PImage curPic;
  //int frame; // for animation

  TitleZombie (float xpos, float ypos) {
    //frame = 0;
    x = xpos;
    y = ypos;
    curPic = zLeft;
    vel = new PVector(0, 0);
  }

  void update(PVector target) {
    if (random(1) < 0.05) { // 5% chance to update target
      this.vel.x = target.x-this.x;
      this.vel.y = target.y-this.y;
      this.vel.normalize();
      if (this.vel.x < 0) {
        this.curPic = zLeft; //[this.frame];
      } else if (this.vel.x > 0) {
        this.curPic = zRight; //[this.frame];
      }
    }
    this.x += this.vel.x;
    this.y += this.vel.y;
  }
}

class Drop {
  float x, y;
  final color col = (#0F80F5); //color(155, 47, 47); //(#0F80F5);
  boolean inFront;
  float speed;
  Drop() {
    x = random(width);
    y = random(-height, grass);
    inFront = bool(str(round(random(1))));
    speed = round(random(2, 3) + random(1, 2));
  }

  void update() { 
    this.y += speed;
    if (this.y > grass) {
      this.y = random(-1 * height, 0);
      this.x = random(width);
    }
  }
}

