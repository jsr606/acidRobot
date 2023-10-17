public class Robot {

  PApplet parent;

  public boolean initialized = false;

  // serial port
  String robotSerialPort = "";
  Serial robotSerial;
  int serialFrequency = 100, lastSerial = millis();
  boolean robotIdle = true;

  // robot variables
  boolean motorsAttached = true;
  String incomingChars, lastCommand, feedbackString = "", incomingCoordinates = "", incomingMessage = "", lastIncomingMessage = "";
  public ArrayList feedbackMessages, robotCommands;
  int amountOfFeedbackMessages = 80;

  // setup robot keys and knobs
  String robotKeys = "keys.json";
  JSONArray keyData, newKeyData, settings;
  public int amountOfKeys;
  Key [] keys;
  int calibrationKey = -1;

  // setup motion / movement parameters
  boolean robotIsDown = false;
  public float zHover = 10, zPush = -1, speed = 80;
  int currentKey = -1, futureKey = -1;
  public float [] robotCoords = new float [3];

  public Robot(PApplet parent, String theSerialPort) {
    
    this.parent = parent;
    parent.registerMethod("dispose", this);

    // setup serial
    println("serial ports:");
    printArray(Serial.list());
    robotSerialPort = theSerialPort;
    robotSerial = new Serial(parent, robotSerialPort, 115200);
    println("connected to serial "+robotSerialPort);
    feedbackMessages = new ArrayList();
    robotCommands = new ArrayList();

    // load general settigns
    settings = loadJSONArray("settings.json");
    JSONObject _settings = settings.getJSONObject(0);
    amountOfKeys = _settings.getInt("amountOfKeys");
    zHover = _settings.getFloat("zHover");
    zPush = _settings.getFloat("zPush");
    speed = _settings.getFloat("speed");
    println("loaded settings [settings.json]");
    println("name: "+_settings.getString("name"));
    println("amount of keys: "+amountOfKeys);
    println("zHover: "+zHover);
    println("zPush: "+zPush);
    println("speed: "+speed);
    
    // setup keys / knobs
    keys = new Key [amountOfKeys];
    keyData = loadJSONArray(robotKeys);
    newKeyData = new JSONArray();
    createKeys(amountOfKeys);
    checkKeys();
    
  }
  
  public boolean matchesSerialName(String s){
  
    return robotSerial.toString().equals(s);
  
  }
  
  public void update() {
    
    if (!initialized) {
      // first run
      delay(1000);
      sendData("M2122 V1\n"); // sends feedback when robot stops / has reached destination
      // sendData("M2120 V0.2\n"); // send continuos coordinate feedback, this is not a good idea, seems like too much serial activity makes movement jerky
      initialized = true;
    }
    
    if (robotIdle && robotCommands.size() > 0) {
      if (serialFrequency + lastSerial < millis()) {
        sendNextRobotCommand();
      }
    }
    
  }

  void sendNextRobotCommand() {
    String data = (String) robotCommands.get(0);
    robotSerial.write(data);
    feedbackMessages.add("TX: "+data);
    robotIdle = false;
    lastSerial = millis();
  }

  public void dispose() {
    // Anything in here will be called automatically when the parent sketch shuts down.
  }

  class Key {
    public float x, y, z;
    public float screenX, screenY;
    public String keyName;
    public int id, zone;
    public Key (int theID, String theKeyName, float theX, float theY, float theZ, int theZone) {
      keyName = theKeyName;
      x = theX;
      y = theY;
      z = theZ;
      id = theID;
      zone = theZone;
    }
  }
  public void serialEvent() {
  
    char incomingChar = robotSerial.readChar();
    incomingMessage += incomingChar;
    if (incomingChar == 10 || incomingChar == 13) {
      parseIncomingSerial();
    }
  
  }
  
  
  void keyCalibrate() {

    sendData("#1 P2220\n"); // ask for current coordinates
    delay(200);

    if (calibrationKey == -1) {
      println("welcome to key calibration mode");
      calibrationKey = 0;
    }

    Key _k = keys[calibrationKey];
    JSONObject k = new JSONObject();
    k.setInt("id", calibrationKey);
    k.setFloat("x", robotCoords[0]);
    k.setFloat("y", robotCoords[1]);
    k.setFloat("z", robotCoords[2]);
    k.setString("name", _k.keyName);
    k.setInt("zone", 0);
    k.setFloat("push", 11);

    newKeyData.append(k);
    println("added "+_k.keyName);
    saveJSONArray(newKeyData, "data/newKeyData.json");
    println("saved key "+_k.keyName+" to data/newKeyData.json");
    calibrationKey++;

    if (calibrationKey == amountOfKeys) {
      println("calibration done, thanks");
      calibrationKey = -1;
    }
  }

  void attachDetach() {
    // detach / attach servo motors
    motorsAttached = !motorsAttached;
    if (motorsAttached) {
      println("attaching servos");
      sendData("M17\n");
    } else {
      println("detaching servos");
      sendData("M2019\n");
    }
  }

  void pause(int theDelay) {
    robotCommands.add(wait(theDelay));
  }

  void pushButton(int theFutureKey, int theTime) {
    moveTo(currentKey); // lift if down

    robotCommands.add(rotateServo(90));
    robotCommands.add(hoverCoords(theFutureKey));
    robotCommands.add(pushCoords(theFutureKey));
    robotCommands.add(wait(theTime));
    robotCommands.add(hoverCoords(theFutureKey));

    currentKey = theFutureKey;

    feedbackMessages.add("pushing "+theFutureKey);
  }

  void moveTo(int theFutureKey) {

    if (robotIsDown) {
      robotCommands.add(hoverCoords(currentKey)); // if robot is down, raise it up before doing any moves
      robotIsDown = false;
    }

    if (theFutureKey != currentKey) {

      if (keys[theFutureKey].zone != keys[currentKey].zone) {
        robotCommands.add(homeCoords()); // new key zone, add homing
      }

      robotCommands.add(hoverCoords(theFutureKey));
      currentKey = theFutureKey;
    }
  }

  String wait(int waitTime) {
    waitTime = max(waitTime, 0);
    String data = "#1 G2004 P"+waitTime+"\n";
    return data;
  }

  String moveTo(float _x, float _y, float _z) {
    String data = "#1 G1 X"+fixDec(_x)+" Y"+fixDec(_y)+" Z"+fixDec(_z)+" F"+int(speed)+"\n";
    return data;
  }

  void moveRandom() {
    float x = random(150, 220);
    float y = random(-76, 115);
    float z = random(55, 120);
    robotCommands.add(moveTo(x, y, z));
  }

  String hoverCoords(int theKey) {
    String data = "#1 G1 X"+fixDec(keys[theKey].x)+" Y"+fixDec(keys[theKey].y)+" Z"+fixDec(keys[theKey].z+zHover)+" F"+int(speed)+"\n";
    return data;
  }

  String pushCoords(int theKey) {
    String data = "#1 G1 X"+fixDec(keys[theKey].x)+" Y"+fixDec(keys[theKey].y)+" Z"+fixDec(keys[theKey].z+zPush)+" F"+int(speed)+"\n";
    return data;
  }

  String homeCoords() {
    String data = "#1 G1 X172 Y150 Z100 F"+int(speed)+"\n";
    return data;
  }

  String rotateServo(float _r) {
    _r = 180-_r;
    constrain(_r, 0, 180);
    String data = "#1 G2202 N3 V"+fixDec(_r)+" F1\n";
    return data;
  }

  void createKeys(int amountOfKeys) {
    for (int i = 0; i<amountOfKeys; i++) {
      JSONObject k = keyData.getJSONObject(i);
      //println(i+": key id:"+k.getInt("id")+" name "+k.getString("name")+" x "+k.getFloat("x")+" y "+k.getFloat("y")+ " z "+k.getFloat("z"));
      keys[i] = new Key(k.getInt("id"), k.getString("name"), k.getFloat("x"), k.getFloat("y"), k.getFloat("z"), k.getInt("zone"));
    }
  }

  void checkKeys() {
    //println("keys on this robot ["+robotKeys+"]");
    for (int i = 0; i<keys.length; i++) {
      Key k = (Key) keys[i];
      //println(i+": key id: "+k.id+" name "+k.keyName+" x "+k.x+" y "+k.y+ " z "+k.z+" zone "+k.zone);
    }
  }

  float fixDec(float n) {
    return Float.parseFloat(String.format("%." + 3 + "f", n).replace(',', '.'));
  }

  void sendData(String theData) {
    feedbackMessages.add("TX: "+theData);
    robotSerial.write(theData);
    lastCommand = theData;
    lastSerial = millis();
  }

  synchronized void parseIncomingSerial() {
    //println("incoming: "+incomingMessage);
    if (incomingMessage.contains("X") && incomingMessage.contains("Y") && incomingMessage.contains("Z")) {
      //println("this is coordinates");
      incomingCoordinates = incomingMessage;
      parseIncomingCoordinates();
    } else if (incomingMessage.contains("@9 V0")) {
      // arrived at destination
      currentKey = futureKey;
      feedbackMessages.add("RX: "+incomingMessage);
      sendData("#1 P2220\n"); // ask for current coordinates
      //println("arrived at destination");
    } else if (incomingMessage.contains("$1 E")) {
      println("problems with move command"+incomingMessage);
    } else if (incomingMessage.contains("$1 ok")) {
      // move on
      if (robotCommands.size() > 0) robotCommands.remove(0);
      robotIdle = true;
    }

    //while (feedbackMessages.size() > amountOfFeedbackMessages) feedbackMessages.remove(0);
    incomingMessage = "";
  }

  void parseIncomingCoordinates() {
    //println("incoming coord raw: "+incomingCoordinates);
    String[] coords = split(incomingCoordinates, " ");
    //println("len: "+coords.length);
    for (int i = 2; i<coords.length; i++) {
      //println(coords[i].substring(1));
      robotCoords[i-2] = float(coords[i].substring(1));
    }
  }
}
