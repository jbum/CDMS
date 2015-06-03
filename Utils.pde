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
  paper.beginDraw();
    paper.smooth(8);
    paper.noFill();
    paper.stroke(penColor);
    paper.strokeJoin(ROUND);
    paper.strokeCap(ROUND);
    paper.strokeWeight(penWidth);
  paper.endDraw();
}

void nudge(int direction, int kc)
{
  if (selectedObject != null) {
    selectedObject.nudge(direction, kc);
  }
  doSaveSetup();
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
  if (direction != 0) {
    doSaveSetup();
  }
}

void advancePenWidth(int direction) {
  penWidthIdx = (penWidthIdx + penWidths.length + direction) % penWidths.length;
  penWidth = penWidths[penWidthIdx]; 
  paper.beginDraw();
  paper.strokeWeight(penWidth);
  paper.endDraw();
  if (direction != 0) {
    doSaveSetup();
  }
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

class CDMSSetup {
  int[][] setupTeeth;
  float[][] setupMounts;
  float[][] setupPens;
  Boolean[][] setupInversions;
  int penColorIdx, penWidthIdx;

  CDMSSetup(int setupMode, int penColorIdx, int penWidthIdx, int[][] setupTeeth, float[][] setupMounts, float[][] setupPens, Boolean[][] setupInversions)
  {
    this.penColorIdx = penColorIdx;
    this.penWidthIdx = penWidthIdx;
    this.setupMode = setupMode;
    this.setupTeeth = setupTeeth;
    this.setupMounts = setupMounts;
    this.setupPens = setupPens;
    this.setupInversions = setupInversions;
  }
};


void doSaveSetup()
{
  CDMSSetup tsetup = new CDMSSetup(setupMode, penColorIdx, penWidthIdx, setupTeeth, setupMounts, setupPens, setupInversions);
  jsSaveSetups(tsetup);
}

void doLoadSetup()
{
  CDMSSetup tsetup = new CDMSSetup(setupMode, penColorIdx, penWidthIdx, setupTeeth, setupMounts, setupPens, setupInversions);
  jsLoadSetups(tsetup);
  setupTeeth = tsetup.setupTeeth;
  setupMounts = tsetup.setupMounts;
  setupPens = tsetup.setupPens;
  setupInversions = tsetup.setupInversions;
  setupMode = tsetup.setupMode;
  penColorIdx = tsetup.penColorIdx;
  penWidthIdx = tsetup.penWidthIdx;
  advancePenColor(0);
  advancePenWidth(0);
}

void issueCmd(String cmd, String subcmd) {
  if (cmd.equals("play")) {
      passesPerFrame = 1;
      isMoving = true;
      drawDirection = 1;
      myLastFrame = -1;
  } else if (cmd.equals("pause")) {
      isMoving = false;
      drawDirection = 1;
      myLastFrame = -1;
  } else if (cmd.equals("ff")) {
      passesPerFrame = 10;
      drawDirection = 1;
      isMoving = true;
  } else if (cmd.equals("fff")) {
      drawDirection = 1;
      completeDrawing();
  } else if (cmd.equals("rr")) {
      drawDirection = -1;
      passesPerFrame = 1;
      isMoving = true;
  } else if (cmd.equals("rrr")) {
      drawDirection = -1;
      passesPerFrame = 10;
      isMoving = true;
  } else if (cmd.equals("erase")) {
      clearPaper();
  } else if (cmd.equals("setup")) {
      int setupMode = int(subcmd);
      deselect();
      drawingSetup(setupMode, false);
      doSaveSetup();
  } else if (cmd.equals("snapshot")) {
    alert("Coming Soon!");
  }
}
