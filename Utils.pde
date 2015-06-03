String saveFilename(String prefix)
{
  String sf = prefix + year() + "-" + month() + "-" + day() + "_" + hour() + "." + minute() + "." + second() + ".png";
  return sf;
}


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

Boolean isDragging = false;
float startDragX = 0, startDragY= 0;

void drag() {
  if (selectedObject != null) {
    int direction=0, keycode=0;

    if (!isDragging) {
      startDragX = pmouseX;
      startDragY = pmouseY;
      isDragging = true;
    }
    //!!  for ConnectingRod - use a similar system as for penrig to move it's mountpoint - do NOT do swaps (maybe do them by double-clicking on swivel?)
    //
    if (selectedObject instanceof Gear) {
      Gear g = (Gear) selectedObject;
      float dm = dist(mouseX, mouseY, g.x, g.y);
      float ds = dist(startDragX, startDragY, g.x, g.y);
      if (abs(dm-ds) > 10) {
        direction = (dm > ds)? 1 : -1;
        keycode = (direction == 1)? UP : DOWN;
        startDragX = mouseX;
        startDragY = mouseY;
      }
    } else if (selectedObject instanceof PenRig) {
      // For pen arm, use startX, endX to get closest anchor point on pen arm.  Then reposition/rotate so that anchorP is as close as possible to mouseX/mouseY
      // using proper penarm quantization.
      // we solve rotation first (using mouse -> arm pivot, translated for parent), then length is fairly easy.
      //
      PenRig pr = (PenRig) selectedObject;
      float dm = dist(mouseX, mouseY, startDragX, startDragX);
      if (abs(dm) > 10) {
        PVector ap = pr.itsMP.getPosition(); // position of mount
        PVector pp = pr.getPosition(); // position of pen
        float gPenAngle = atan2(pp.y-ap.y,pp.x-ap.x);
        float lAngleOffset = radians(pr.angle) - gPenAngle; // adjustment to stored angle, in radians
        float desiredAngle = atan2(mouseY-ap.y,mouseX-ap.x);
        pr.angle = degrees(desiredAngle+lAngleOffset);
        pr.angle = round(pr.angle / 5)*5;
        float oLen = dist(startDragX,startDragY,ap.x,ap.y);
        float desLen = dist(mouseX, mouseY, ap.x, ap.y);
        pr.len -= (desLen-oLen)/(0.5*inchesToPoints);
        pr.len = round(pr.len / 0.125)*0.125;
        setupPens[setupMode][1] = pr.angle;
        setupPens[setupMode][0] = pr.len;
        doSaveSetup();
        startDragX = mouseX;
        startDragY = mouseY;
      }
    } else {
      float dm = dist(mouseX, mouseY, startDragX, startDragX);
      if (abs(dm) > 10) {
        float a = atan2(mouseY-startDragY, mouseX-startDragX);
        if (a >= -PI/4 && a <= PI/4) {
          direction = 1;
          keycode = RIGHT;
        } else if (a >= 3*PI/4 || a <= -3*PI/4) {
          direction = -1;
          keycode = LEFT;
        } else if (a >= -3*PI/4 && a <= -PI/4) {
          direction = 1;
          keycode = UP;
        } else if (a >= PI/4 && a <= 3*PI/4) {
          direction = -1;
          keycode = DOWN;
        }
        startDragX = mouseX;
        startDragY = mouseY;
      }
    }
    if (direction != 0)
      nudge(direction, keycode);
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

void doSnapshot() 
{
  //
  // background(255);
  // image(paper,0,0);
  // save("untitled.png");
  makeSnapshot(paper, turnTable.rotation, saveFilename("cdm_"));
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
    doSnapshot();
  }
}

String getSetupMode()
{
  return setupMode;
}

int getDrawDirection()
{
  return drawDirection;
}

int getPassesPerFrame()
{
  return passesPerFrame;
}

Boolean getIsMoving()
{
  return isMoving;
}
