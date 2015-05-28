String saveFilename()
{
  String sf = "cdm_" + year() + "-" + month() + "-" + day() + "_" + hour() + "." + minute() + "." + second() + ".png";
  return sf;
}

void saveSnapshot()
{
    PGraphics tmp = createGraphics(paper.width, paper.height);
    String sf = saveFilename();
    tmp.beginDraw();
    tmp.smooth();
    tmp.background(255);
    tmp.image(paper, 0, 0);
    tmp.endDraw();
    tmp.save(sf);
    println("Frame saved as " + sf);
    for (Gear g : activeGears) {
      println("Gear " + g.nom + " has " + g.teeth + " teeth");
    }
}

int[] gTeeth = { // currently unused
  30, 32, 34, 36, 40, 48, 50, 58, 60, 66, 72, 74, 80, 90, 94, 98, 100, 120, 144, 150, 151
 };


int findNextTeeth(int teeth, int direction) {
  println("Finding next tooth: " + teeth + " dir " + direction);
  if (direction == 1) {
      for (int i = 0; i < gTeeth.length; ++i) {
        if (gTeeth[i] > teeth)
          return gTeeth[i];
      }
      return gTeeth[0];
  } else {
      for (int i = gTeeth.length-1; i >= 0; --i) {
        if (gTeeth[i] < teeth)
          return gTeeth[i];
      }
      return gTeeth[gTeeth.length-1];
  }
}

int GCD(int a, int b) {
   if (b==0) return a;
   return GCD(b,a%b);
}

// Currently seems correct for all but stacked gear layouts
// Correct answer for layout 'C' is 20

int computeCyclicRotations() {
  // Compute total turntable rotations for current drawing - needs work!
  int a = 1; // running minimum
  for (Gear g : activeGears) {
    if (g.contributesToCycle && g != turnTable) {
      int b = g.teeth / GCD(g.teeth, turnTable.teeth);
      println("  b = " + b);
      a = max(a,max(a,b)*min(a,b)/ GCD(a, b));
    }
  }
  return a;
}

void completeDrawing()
{
    // paper.beginDraw();
    // paper.clear();
    // paper.endDraw();
    myFrameCount = 0;
    penRaised = true;
    // isStarted = false;
    int totalRotations = computeCyclicRotations();
    println("Cyclic Rotations = " + totalRotations);
    int framesPerRotation = int(TWO_PI / crankSpeed);
    myLastFrame = framesPerRotation * totalRotations + 1;
    passesPerFrame = 360;
    isMoving = true;
}
