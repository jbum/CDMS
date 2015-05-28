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
