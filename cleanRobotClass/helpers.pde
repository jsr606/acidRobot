// computationally generate lots of buttons / grid controller

void makeKeys() {
  
  JSONArray newKeyData;
  newKeyData = new JSONArray();
  
  int i = 0;
  for (int y = 0; y<8; y++) {
    for (int x = 0; x<8; x++) {
      JSONObject k = new JSONObject();
      k.setInt("id", i);
      k.setFloat("x", 0);
      k.setFloat("y", 0);
      k.setFloat("z", 0);
      k.setString("name", (x+","+y));
      k.setInt("zone", 0);
      newKeyData.append(k);
      i++;
    }
  }
  for (int f = 0; f<8; f++) {
    JSONObject k = new JSONObject();
    k.setInt("id", i);
    k.setFloat("x", 0);
    k.setFloat("y", 0);
    k.setFloat("z", 0);
    k.setString("name", ("f"+f));
    k.setInt("zone", 0);
    newKeyData.append(k);
    i++;
  }
  for (int f = 0; f<8; f++) {
    JSONObject k = new JSONObject();
    k.setInt("id", i);
    k.setFloat("x", 0);
    k.setFloat("y", 0);
    k.setFloat("z", 0);
    k.setString("name", ("F"+char(65+f)));
    k.setInt("zone", 0);
    newKeyData.append(k);
    i++;
  }
  saveJSONArray(newKeyData, "data/madeKeys.json");
}
