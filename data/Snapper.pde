// Snapper - for paper snapshots

void setup() {
    size(648,648);
    noLoop();
}

void draw() {
    background(255);
}

void snapPicture(PGraphics paper, float rotation) {
   background(255);

   pushMatrix();
      translate(width/2, height/2);
      rotate(rotation);
      image(paper, -paper.width/2, -paper.width/2);
   popMatrix();
   save("untitled.png");
}
