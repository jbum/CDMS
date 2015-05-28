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
