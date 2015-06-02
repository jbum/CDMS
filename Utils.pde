String getSetupString()
{
  String ss = "Setup\t" + ((char) (65+ setupMode)) + "\n";
  ss += "Gear Teeth\t";
  for (int i = 0; i < setupTeeth[setupMode].length; ++i) {
    if (i > 0)  ss += "\t";
    ss += setupTeeth[setupMode][i];
  }
  ss += "\nMount Points\t";
  for (int i = 0; i < setupMounts[setupMode].length; ++i) {
    if (i > 0)  ss += "\t";
    ss += setupMounts[setupMode][i];
  }
  ss += "\n";
  ss += "Pen\t" + penRig.len + "\t" + penRig.angle + "°" + "\n";
  return ss;
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
    ((ConnectingRod) selectedObject).invert();
  } else if (activeConnectingRods.size() == 1) {
    activeConnectingRods.get(0).invert();
  } else {
    println("Please select a connecting rod to invert");
  }
}

void completeDrawing()
{
    myFrameCount = 0;
    penRaised = true;
    int totalRotations = computeCyclicRotations();
    // println("Total turntable cycles needed = " + totalRotations);
    int framesPerRotation = int(TWO_PI / crankSpeed);
    myLastFrame = framesPerRotation * totalRotations + 1;
    passesPerFrame = 360*2;
    isMoving = true;
}

void clearPaper() 
{
  paper = createGraphics(paperWidth, paperWidth);
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
}

void advancePenWidth(int direction) {
  penWidthIdx = (penWidthIdx + penWidths.length + direction) % penWidths.length;
  penWidth = penWidths[penWidthIdx]; 
  paper.beginDraw();
  paper.strokeWeight(penWidth);
  paper.endDraw();
}

void drawFulcrumLabels() {
    textFont(nFont);
    textAlign(CENTER);
    fill(64);
    stroke(92);
    strokeWeight(0.5);
    pushMatrix();
      translate(3.1*inchesToPoints, 10.23*inchesToPoints);
      rotate(PI/2);
      int nbrNotches = 39;
      float startNotch = 0.25*inchesToPoints;
      float notchIncr = 0.25*inchesToPoints;
      float minNotch = 0.9*inchesToPoints;
      float lilNotch = minNotch/2;
      float widIncr = 1.722*inchesToPoints/nbrNotches;
      float notchSize = minNotch;
      float notchX = -startNotch;
      for (int n = 0; n < 39; ++n) {
        line(notchX,0,notchX,n % 2 == 1? notchSize : lilNotch);
        if (n % 2 == 1) {
          text("" + int(n/2+1),notchX,lilNotch); 
        }
        notchSize += widIncr;
        notchX -= notchIncr;
      }
    popMatrix();

}
