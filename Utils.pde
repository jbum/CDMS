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
      println(g.teeth  + "  b = " + b);
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
    passesPerFrame = 360*2;
    isMoving = true;
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
