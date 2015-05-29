String saveFilename()
{
  String sf = "cdm_" + year() + "-" + month() + "-" + day() + "_" + hour() + "." + minute() + "." + second() + ".png";
  return sf;
}

void saveSnapshot()
{
    String sf = saveFilename();
    saveSnapshotAs(sf);
    println("Frame saved as " + sf);
    // Feedback
    for (Gear g : activeGears) {
      println("Gear " + g.nom + " has " + g.teeth + " teeth");
    }
}

void saveSnapshotAs(String sf)
{
    PGraphics tmp = createGraphics(paper.width, paper.height);
    tmp.beginDraw();
    tmp.smooth();
    tmp.background(255);
    tmp.image(paper, 0, 0);
    tmp.endDraw();
    tmp.save(sf);
}


int GCD(int a, int b) {
   if (b==0) return a;
   return GCD(b,a%b);
}


// Compute total turntable rotations for current drawing
int computeCyclicRotations() {
  int a = 1; // running minimum
  int idx = 0;
  for (Gear g : activeGears) {
    if (g.contributesToCycle && g != turnTable) {
      int ratioNom = turnTable.teeth;
      int ratioDenom = g.teeth;
      if (g.isMoving) { // ! cheesy hack for our orbit configuration, assumes anchorTable,anchorHub,orbit configuration
        ratioNom = turnTable.teeth * (activeGears.get(idx-1).teeth + g.teeth);
        ratioDenom = activeGears.get(idx-2).teeth * g.teeth;
        int gcd = GCD(ratioNom, ratioDenom);
        ratioNom /= gcd;
        ratioDenom /= gcd;
      }
      int b = min(ratioNom,ratioDenom) / GCD(ratioNom, ratioDenom);
      // println(g.teeth  + " " + ratioNom + "/" + ratioDenom + "  b = " + b);
      a = max(a,max(a,b)*min(a,b)/ GCD(a, b));
    }
    idx += 1;
  }
  return a;
}

void invertConnectingRod()
{
  if (selectedObject instanceof ConnectingRod) {
    ((ConnectingRod) selectedObject).nudge(1, UP);
  } else if (activeConnectingRods.size() == 1) {
    activeConnectingRods.get(0).nudge(1, UP);
  } else {
    println("Please select a connecting rod to invert");
  }
}

void completeDrawing()
{
    myFrameCount = 0;
    penRaised = true;
    int totalRotations = computeCyclicRotations();
    println("Total turntable cycles needed = " + totalRotations);
    int framesPerRotation = int(TWO_PI / crankSpeed);
    myLastFrame = framesPerRotation * totalRotations + 1;
    passesPerFrame = 360*2;
    isMoving = true;
}

void clearPaper() 
{
     paper.beginDraw();
     paper.clear();
     paper.endDraw();
}

void measureGears() {
  float[] sav = {0,0,0,0,0,0,0,0,0};
  int i = 0;
  for (Gear g : activeGears) {
      sav[i] = g.rotation;
      i++;
  }
  myFrameCount += 1;
  turnTable.crank(myFrameCount*crankSpeed); // The turntable is always the root of the propulsion chain, since it is the only required gear.
  i = 0;
  for (Gear g : activeGears) {
      sav[i] = g.rotation;
      i++;
      // Turntable should be crankSpeed
      println(g.teeth + ": " + (g.rotation - sav[i])/crankSpeed);
  }

}

void nudge(int direction, int kc)
{
  if (selectedObject != null) {
    selectedObject.nudge(direction, kc);
  }
}

void deselect() {
  if (selectedObject != null) {
    selectedObject.unselect();
    selectedObject = null;
  }
}

void advancePenColor(int direction) {
  penColorIdx = (penColorIdx + penColors.length + direction) % penColors.length;
  penColor = penColors[penColorIdx]; 
  paper.beginDraw();
  paper.stroke(penColor);
  paper.endDraw();
  println("Pen color changed");
}

void advancePenWidth(int direction) {
  penWidthIdx = (penWidthIdx + penWidths.length + direction) % penWidths.length;
  penWidth = penWidths[penWidthIdx]; 
  paper.beginDraw();
  paper.strokeWeight(penWidth);
  paper.endDraw();
  println("Pen width set to " + penWidth);
}


void toggleHiresmode()
{
  hiresMode = !hiresMode;
  PGraphics oldPaper = paper; 
  if (hiresMode) {
    paperScale = 2;
    println("Hires ON - saved frames are twice the size, drawings are 4 times as slow");
  }
  else {
    paperScale = 1;
    println("Hires OFF");
  }
  paperWidth = 9*inchesToPoints*paperScale;
  paper = createGraphics(int(paperWidth), int(paperWidth));
  clearPaper();
  paper.beginDraw();
  paper.image(oldPaper,0,0,paper.width,paper.height);
  paper.endDraw();
  penRaised = true;
}

