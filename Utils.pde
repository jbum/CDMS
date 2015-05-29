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


// Compute total turntable rotations for current drawing - needs work!
int computeCyclicRotations() {
  int a = 1; // running minimum
  int idx = 0;
  for (Gear g : activeGears) {
    if (g.contributesToCycle && g != turnTable) {
      int ratioNom = turnTable.teeth;
      int ratioDenom = g.teeth;
      if (g.isMoving) { // cheesy hack for our orbit configuration, assumes anchorTable,anchorHub,orbit configuration
        ratioNom = turnTable.teeth * (activeGears.get(idx-1).teeth + g.teeth);
        ratioDenom = activeGears.get(idx-2).teeth * g.teeth;
        int gcd = GCD(ratioNom, ratioDenom);
        ratioNom /= gcd;
        ratioDenom /= gcd;
      }
      int gcd = GCD(ratioNom, ratioDenom);
      int ratioNomR = ratioNom / gcd;
      int ratioDenomR = ratioDenom / gcd;
      int b = min(ratioNomR,ratioDenomR) / GCD(ratioNomR, ratioDenomR);
      println(g.teeth  + " " + ratioNom + "/" + ratioDenom + "  b = " + b);
      a = max(a,max(a,b)*min(a,b)/ GCD(a, b));
    }
    idx += 1;
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
