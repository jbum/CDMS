// Simulation of Cycloid Drawing Machine
//
// Physical machine designed by Joe Freedman  kickstarter.com/projects/1765367532/cycloid-drawing-machine
// Processing simulation by Jim Bumgardner    krazydad.com
//

float inchesToPoints = 72;

float bWidth = 18.14;
float bHeight = 11.51;
float pCenterX = 8.87;
float pCenterY = 6.61;
float toothRadius = 0.0956414*inchesToPoints;
float meshGap = 1.5/25.4*inchesToPoints; // 1 mm gap needed for meshing gears
PFont  gFont, hFont;
PImage titlePic;

int[] gTeeth = { // currently unused
  30, 32, 34, 36, 40, 48, 50, 58, 60, 66, 72, 74, 80, 90, 94, 98, 100, 120, 144, 150, 151
 };

int setupMode = 2; // 0 = simple, 1 = moving pivot, 2 = orbiting gear, 3 = orbit gear + moving pivot
boolean invertPen = true;

ArrayList<Gear> activeGears;
ArrayList<Channel> rails;

Gear crank, turnTable;
MountPoint slidePoint, anchorPoint, discPoint;
Channel crankRail, anchorRail, pivotRail;

ConnectingRod cRod;
PenRig penRig;

boolean animateMode = false;
PGraphics paper;
float paperWidth = 9*inchesToPoints;
float crankSpeed = 0.01;  // rotation per frame  - 0.2 is nice.
int passesPerFrame = 1;

boolean isStarted = false;
boolean isMoving = false;


void setup() {
  size(int(bWidth*inchesToPoints)+100, int(bHeight*inchesToPoints));
  ellipseMode(RADIUS);
  gFont = createFont("EurostileBold", 32);
  hFont = createFont("EurostileBold", 18);
  titlePic = loadImage("title.png");
  
  activeGears = new ArrayList<Gear>();
  rails = new ArrayList<Channel>();

  // Board Setup

  paper = createGraphics(int(paperWidth), int(paperWidth));

  discPoint = new MountPoint("DP", pCenterX, pCenterY);
  rails.add(new LineRail(2.22, 10.21, .51, .6));
  rails.add(new LineRail(3.1, 10.23, 3.1, .5));
  rails.add(new LineRail(8.74, 2.41, 9.87, .47));
  rails.add(new ArcRail(pCenterX, pCenterY, 6.54, radians(-68), radians(-5)));
  rails.add(new ArcRail(8.91, 3.91, 7.79, radians(-25), radians(15)));

  float[] rbegD = {
    4.82, 4.96, 4.96, 4.96, 4.96, 4.96
  };
  float[] rendD = {
    7.08, 6.94, 8.46, 7.70, 7.96, 8.48
  };
  float[] rang = {
    radians(-120), radians(-60), radians(-40), radians(-20), 0, radians(20)
  };

  for (int i = 0; i < rbegD.length; ++i) {
      float x1 = pCenterX + cos(rang[i])*rbegD[i];
      float y1 = pCenterY + sin(rang[i])*rbegD[i];
      float x2 = pCenterX + cos(rang[i])*rendD[i];
      float y2 = pCenterY + sin(rang[i])*rendD[i];
      rails.add(new LineRail(x1, y1, x2, y2));
  }

  // Drawing Setup
  switch (setupMode) {
  case 0: // simple set up with one gear for pen arm
    turnTable = addGear(120); 
    crank = addGear(98);
    crankRail = rails.get(10);
    pivotRail = rails.get(1);
    crank.mount(crankRail,0);
    turnTable.mount(discPoint, 0);
    crank.snugTo(turnTable);
    turnTable.meshTo(crank); 
    slidePoint = new MountPoint("SP", pivotRail, 0.1);
    anchorPoint = new MountPoint("AP", crank, 0.47);
    if (invertPen)
      cRod = new ConnectingRod(anchorPoint, slidePoint);
    else
      cRod = new ConnectingRod(slidePoint, anchorPoint);
    
    penRig = new PenRig(2.0, PI/2 * (invertPen? -1 : 1), cRod, 7.4);
    break;

  case 1: // moving fulcrum & separate crank
    turnTable = addGear(120); 
    crank = addGear(100);
    Gear anchor = addGear(98);
    Gear fulcrumGear = addGear(48);
    crankRail = rails.get(1);
    anchorRail = rails.get(10);
    pivotRail = rails.get(0);
    crank.mount(crankRail, 0.735+.1);
    anchor.mount(anchorRail,0);
    fulcrumGear.mount(pivotRail, 0.29-.1);
    turnTable.mount(discPoint, 0);

    anchor.snugTo(turnTable);
    crank.snugTo(turnTable);
    fulcrumGear.snugTo(crank);    

    turnTable.meshTo(crank);
    anchor.meshTo(turnTable);
    fulcrumGear.meshTo(crank);   

    slidePoint = new MountPoint("SP", fulcrumGear, 0.5);
    anchorPoint = new MountPoint("AP", anchor, 0.47);
    if (invertPen)
      cRod = new ConnectingRod(anchorPoint, slidePoint);
    else
      cRod = new ConnectingRod(slidePoint, anchorPoint);
    penRig = new PenRig(3.0, PI/2 * (invertPen? -1 : 1), cRod, 7.4);

    break;
    
  case 2: // orbiting gear
    crankRail = rails.get(9);
    anchorRail = rails.get(4);
    pivotRail = rails.get(1);
    
    // Always need these...
    turnTable = addGear(150);
    crank = addGear(50);                
  
    // These are optional
    Gear  anchorTable = addGear(100);
    Gear  anchorHub = addGear(36);
    Gear  orbit = addGear(40);
  
    orbit.isMoving = true;
  
    // Setup gear relationships and mount points here...
    crank.mount(crankRail, 0);
    turnTable.mount(discPoint, 0);
    crank.snugTo(turnTable);
    turnTable.meshTo(crank);
  
    // crank.meshTo(turnTable, crankRail, .52); // crank
    // turnTable.meshTo(crank, discPoint);
    anchorTable.mount(anchorRail, .315);
    anchorTable.snugTo(crank);
    anchorTable.meshTo(crank);

    anchorHub.stackTo(anchorTable);
    anchorHub.isFixed = true;

    orbit.mount(anchorTable,0);
    orbit.snugTo(anchorHub);
    orbit.meshTo(anchorHub);
  
    // Setup Pen
    slidePoint = new MountPoint("SP", pivotRail, 1-0.1027);
    anchorPoint = new MountPoint("AP", orbit, 0.47);
    if (invertPen)
      cRod = new ConnectingRod(anchorPoint, slidePoint);
    else
      cRod = new ConnectingRod(slidePoint, anchorPoint);
    penRig = new PenRig(4.0, (-PI/2) * (invertPen? -1 : 1), cRod, 8.4);
    break;


  case 3: // orbiting gear with rotating fulcrum (#1 and #2 combined)
    crankRail = rails.get(9);
    anchorRail = rails.get(4);
    // pivotRail = rails.get(1);
    Channel fulcrumCrankRail = rails.get(1);
    Channel fulcrumGearRail = rails.get(0);
    
    // Always need these...
    turnTable = addGear(150);
    crank = addGear(50);                
  
    // These are optional
    anchorTable = addGear(100);
    anchorHub = addGear(36);
    orbit = addGear(40);
  
    Gear  fulcrumCrank = addGear(52);                
    fulcrumGear = addGear(42);
  
    orbit.isMoving = true;
  
    // Setup gear relationships and mount points here...
    crank.mount(crankRail, 0);
    turnTable.mount(discPoint, 0);
    crank.snugTo(turnTable);
    turnTable.meshTo(crank);
  
    // crank.meshTo(turnTable, crankRail, .52); // crank
    // turnTable.meshTo(crank, discPoint);
    anchorTable.mount(anchorRail, .315);
    anchorTable.snugTo(crank);
    anchorTable.meshTo(crank);

    anchorHub.stackTo(anchorTable);
    anchorHub.isFixed = true;

    orbit.mount(anchorTable,0);
    orbit.snugTo(anchorHub);
    orbit.meshTo(anchorHub);


    fulcrumCrank.mount(fulcrumCrankRail, 0.735+.1);
    fulcrumGear.mount(fulcrumGearRail, 0.29-.1);
    fulcrumCrank.snugTo(turnTable);
    fulcrumGear.snugTo(fulcrumCrank);    

    fulcrumCrank.meshTo(turnTable);
    fulcrumGear.meshTo(fulcrumCrank);   

    // Setup Pen
    slidePoint = new MountPoint("SP", fulcrumGear, 0.5);
    anchorPoint = new MountPoint("AP", orbit, 0.47);
    if (invertPen)
      cRod = new ConnectingRod(anchorPoint, slidePoint);
    else
      cRod = new ConnectingRod(slidePoint, anchorPoint);
    penRig = new PenRig(4.0, (-PI/2) * (invertPen? -1 : 1), cRod, 8.4);
    break;

  }
  turnTable.showMount = false;
}

float lastPX = -1, lastPY = -1;
int myFrameCount = 0;

void draw() 
{

    background(255);
    helpDraw(); // draw help if needed


  // Crank the machine a few times, based on current passesPerFrame - this generates new gear positions and drawing output
  for (int p = 0; p < passesPerFrame; ++p) {
    if (isMoving) {
      myFrameCount += 1;
      crank.crank(myFrameCount*crankSpeed); // this recursive gear moves all the gears based on their relationships.
    }
  
    // work out coords on unrotated paper
    PVector nib = penRig.getPosition();
    float dx = nib.x - pCenterX*inchesToPoints;
    float dy = nib.y - pCenterY*inchesToPoints;
    float a = atan2(dy, dx);
    float l = sqrt(dx*dx + dy*dy);
    float px = paperWidth/2 + cos(a-turnTable.rotation)*l;
    float py = paperWidth/2 + sin(a-turnTable.rotation)*l;
  
    paper.beginDraw();
    if (!isStarted) {
      paper.clear();
      paper.smooth(4);
      paper.noFill();
      paper.stroke(0);
      paper.strokeWeight(0.5);
      // paper.rect(10, 10, paperWidth-20, paperWidth-20);
      isStarted = true;
    } else {
      paper.line(lastPX, lastPY, px, py);
    }
    paper.endDraw();
    lastPX = px;
    lastPY = py;
  }

  // Draw the machine onscreen in it's current state
  pushMatrix();
    fill(200);
    noStroke();

    image(titlePic, 0, height-titlePic.height);
  
    for (Channel ch : rails) {
       ch.draw();
    }
  
    // discPoint.draw();
  
    textFont(gFont);
    textAlign(CENTER);
    for (Gear g : activeGears) {
      g.draw();
    }
  
    penRig.draw();
  
    pushMatrix();
      translate(pCenterX*inchesToPoints, pCenterY*inchesToPoints);
      rotate(turnTable.rotation);
      image(paper, -paperWidth/2, -paperWidth/2);
    popMatrix();

  popMatrix();
}

void keyPressed() {
  switch (key) {
   case ' ':
      isMoving = !isMoving;
      break;
   case '?':
     toggleHelp();
     break;
   case '0':
     isMoving = false;
     break;
   case '1':
     passesPerFrame = 1;
     isMoving = true;
     break;
   case '2':
   case '3':
   case '4':
   case '5':
   case '6':
   case '7':
   case '8':
   case '9':
      passesPerFrame = ((key-'0')-1)*10;
      isMoving = true;
      break;
  }
}

