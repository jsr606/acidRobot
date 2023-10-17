// stripping down to the essentials while making a grid controller

import processing.serial.*;
import controlP5.*;
import themidibus.*;

MidiBus midi;
Robot gridRobot;
ControlP5 cp5;

PFont roboto;

boolean autoPlay = false;
int nextPlay = millis();

float hover = 10;
ArrayList<Robot> robots = new ArrayList<Robot>();


void setup() {
  size(1200, 1400);
  gridRobot = new Robot(this, "/dev/ttyACM2");
  robots.add(gridRobot);
  roboto = loadFont("RobotoSlab-Regular-24.vlw");
  textFont(roboto, 24);

  cp5 = new ControlP5(this);
  cp5.addSlider("hover").setRange(0, 100).setPosition(10, 10).setSize(400,30).setFont(roboto);
  // stylish
  cp5.setColorActive(color(225));
  colorMode(HSB, 255);
  //float h = random(255);
  cp5.setColorBackground(color(random(255), 255, 30));
  cp5.setColorForeground(color(random(255), 255, 150));
  colorMode(RGB);
}


void draw() {
  background(0);
  gridRobot.update();
  if (autoPlay) doAutoPlay();
  if (gridRobot.initialized) onScreenFeedback(10, 100);
}

void doAutoPlay() {
  if (nextPlay < millis()) {
    if (random(10) < 3) {
      gridRobot.pushButton(int(random(0, 64)), int(random(10, 3000)));
    }
    nextPlay = millis()+int(random(500, 5000));
  }
}

void onScreenFeedback(int x, int y) {
  pushMatrix();
  translate(x, y);
  fill(255);
  text("robot coords: "+gridRobot.robotCoords[0]+", "+gridRobot.robotCoords[1]+", "+gridRobot.robotCoords[2], 0, 0);
  stroke(150);
  line(0, 0, width, 0);
  translate(0, 30);
  for (int i = 0; i<gridRobot.feedbackMessages.size(); i++) {
    String msg = (String) gridRobot.feedbackMessages.get(gridRobot.feedbackMessages.size()-1-i);
    text(msg, 0, 20*i);
  }
  translate(width/2, 0);
  for (int i = 0; i<gridRobot.robotCommands.size(); i++) {
    String msg = (String) gridRobot.robotCommands.get(i);
    if (msg !=null) {
      text(msg, 0, 20*i);
    }
  }
  popMatrix();
}

void keyPressed() {
  if (key == 'r') gridRobot.moveRandom();
  if (key == '1') gridRobot.pushButton(0, 10);
  if (key == '2') gridRobot.pushButton(63, 10);
  if (key == 'k') gridRobot.keyCalibrate();
  if (key == 'd') gridRobot.attachDetach();
  if (key == ' ') autoPlay = !autoPlay;
}

// i would like to move the following in to the Robot class
// or alternative check which port is the event is happening on --- myPort.which;

void serialEvent(Serial myPort) {
  char incomingChar;
  try {
    Robot foundRobot = null;
    for(Robot r : robots){
      if (r.matchesSerialName(myPort.toString())){
        foundRobot = r;
        break;
      }
    }
    
    foundRobot.serialEvent();
    //println(myPort.toString());
    
    //incomingChar = myPort.readChar();
    //gridRobot.incomingMessage += incomingChar;
    //if (incomingChar == 10 || incomingChar == 13) {
    //  gridRobot.parseIncomingSerial();
    //}
  }
  catch(RuntimeException e) {
    println("argh, runtime exception");
    e.printStackTrace();
  }
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.getController().getName().equals("hover")) {
    gridRobot.zHover = hover;
  }
}
