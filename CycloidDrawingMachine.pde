// Simulation of Cycloid Drawing Machine
//
// Physical machine designed by Joe Freedman  kickstarter.com/projects/1765367532/cycloid-drawing-machine
// Processing simulation by Jim Bumgardner    krazydad.com
//

static final float inchesToPoints = 72; // controls display scaling
static final float mmToInches = 1/25.4;

float seventyTwoScale = inchesToPoints / 72.0; // Don't change this

float bWidth = 18.14;
float bHeight = 11.51;
float pCenterX = 8.87;
float pCenterY = 6.61;
float toothRadius = 0.0956414*inchesToPoints;
float meshGap = 1.5*mmToInches*inchesToPoints; // 1.5 mm gap needed for meshing gears
PFont  gFont, hFont, nFont;
PImage titlePic;

int setupMode = 0; // 0 = simple, 1 = moving pivot, 2 = orbiting gear, 3 = orbit gear + moving pivot

ArrayList<Gear> activeGears;
ArrayList<MountPoint> activeMountPoints;
ArrayList<Channel> rails;
ArrayList<ConnectingRod> activeConnectingRods;

Selectable selectedObject = null;
Gear crank, turnTable;
MountPoint slidePoint, anchorPoint, discPoint, penMount;
Channel crankRail, anchorRail, pivotRail;

ConnectingRod cRod;
PenRig penRig, selectPenRig = null;

PGraphics paper;
float paperScale = 1;
float paperWidth = 9*inchesToPoints*paperScale;
float crankSpeed = TWO_PI/720;  // rotation per frame  - 0.2 is nice.
int passesPerFrame = 1;
boolean hiresMode = false;

boolean animateMode = false; // for tweening finished drawings
boolean isRecording = false;  // for recording entire window
boolean isStarted = false;
boolean isMoving = false;
boolean penRaised = true;
boolean darkTheme = true;

float lastPX = -1, lastPY = -1;
int myFrameCount = 0;
int myLastFrame = -1;
int recordCtr = 0;

color[] penColors = {color(0,0,0), color(192,0,0), color(0,128,0), color(0,0,128), color(192,0,192)};
color penColor = color(0,0,0);
int penColorIdx = 0;

float[] penWidths = {0.5, 1, 2, 3, 5, 7};
float penWidth = 1;
int penWidthIdx = 1;

void setup() {
  size(int(bWidth*inchesToPoints)+100, int(bHeight*inchesToPoints));
  ellipseMode(RADIUS);
  gFont = createFont("EurostileBold", int(32*seventyTwoScale));
  hFont = createFont("Courier", int(18*seventyTwoScale));
  nFont = createFont("Helvetica-Narrow", int(9*seventyTwoScale)); // loadFont("Notch-Font.vlw");
  titlePic = loadImage(darkTheme? "title_dark.png" : "title.png");
  
  gearInit();
  activeGears = new ArrayList<Gear>();
  activeMountPoints = new ArrayList<MountPoint>();
  activeConnectingRods = new ArrayList<ConnectingRod>();
  
  rails = new ArrayList<Channel>();

  // Board Setup
  
  paper = createGraphics(int(paperWidth), int(paperWidth));
  clearPaper();

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

  drawingSetup(setupMode, true);
}

int[][] setupTeeth = {
    {120,98},
    {120,100,98,48},
    {150,50,100,36,40},
    {150, 98, 100},
    {150, 98, 100},
    {120, 100, 50},
    {150,50,100,36,40,50,60},
  };

float[][] setupMounts = { // mount point measurements
  {0.1, 3, 7.4*inchesToPoints},
  {1.5, 3, 7.4*inchesToPoints},
  {1-0.1027, 1.5, 8.4*inchesToPoints},
  {2, 4, 0.8, 2.5*inchesToPoints, 7.4*inchesToPoints},
  {0.7, 2, 4, 4.5*inchesToPoints, 6.4*inchesToPoints},
  {0.9, 1.5, 4, 0.1, 9.0*inchesToPoints, 3.0*inchesToPoints, 2.2*inchesToPoints},
  {2.5, 1, 8.4*inchesToPoints},
};

Gear addGear(int setupIdx, String nom)
{
  Gear g = new Gear(setupTeeth[setupMode][setupIdx], setupIdx, nom);
  activeGears.add(g);
  return g;
}

MountPoint addMP(int setupIdx, String nom, Channel chan)
{
  MountPoint mp = new MountPoint(nom, chan, setupMounts[setupMode][setupIdx], setupIdx);
  activeMountPoints.add(mp);
  return mp;
}

ConnectingRod addCR(MountPoint slide, MountPoint anchor)
{
  ConnectingRod cr = new ConnectingRod(slide, anchor);
  activeConnectingRods.add(cr);
  return cr;
}

void drawingSetup(int setupIdx, boolean resetPaper)
{
  setupMode = setupIdx;

  println("Drawing Setup: " + setupIdx);
  if (resetPaper) {
    isStarted = false;
  }
  penRaised = true;
  myFrameCount = 0;

  activeGears = new ArrayList<Gear>();
  activeMountPoints = new ArrayList<MountPoint>();
  activeConnectingRods = new ArrayList<ConnectingRod>();
  
   // Drawing Setup
  switch (setupIdx) {
  case 0: // simple set up with one gear for pen arm
    turnTable = addGear(0,"Turntable"); 
    crank = addGear(1,"Crank");
    crankRail = rails.get(10);
    pivotRail = rails.get(1);
    crank.mount(crankRail,0);
    turnTable.mount(discPoint, 0);
    crank.snugTo(turnTable);
    crank.meshTo(turnTable);

    slidePoint = addMP(0, "SP", pivotRail);
    anchorPoint = addMP(1, "AP", crank);
    cRod = addCR(slidePoint, anchorPoint);

    penMount = addMP(2, "EX", cRod);
    penRig = new PenRig(2.0, PI/2, penMount);
    break;

  case 1: // moving fulcrum & separate crank
    turnTable = addGear(0,"Turntable"); 
    crank = addGear(1,"Crank");    crank.contributesToCycle = false;
    Gear anchor = addGear(2,"Anchor");
    Gear fulcrumGear = addGear(3,"FulcrumGear");
    crankRail = rails.get(1);
    anchorRail = rails.get(10);
    pivotRail = rails.get(0);
    crank.mount(crankRail, 0.735+.1);
    anchor.mount(anchorRail,0);
    fulcrumGear.mount(pivotRail, 0.29-.1);
    turnTable.mount(discPoint, 0);

    crank.snugTo(turnTable);
    anchor.snugTo(turnTable);
    fulcrumGear.snugTo(crank);    

    crank.meshTo(turnTable);
    anchor.meshTo(turnTable);
    fulcrumGear.meshTo(crank);   

    slidePoint = addMP(0, "SP", fulcrumGear);
    anchorPoint = addMP(1, "AP", anchor);
    cRod = addCR(slidePoint, anchorPoint);
    penMount = addMP(2, "EX", cRod);
    penRig = new PenRig(3.0, PI/2, penMount);

    break;
    
  case 2: // orbiting gear
    crankRail = rails.get(9);
    anchorRail = rails.get(4);
    pivotRail = rails.get(1);
    
    // Always need these...
    turnTable = addGear(0,"Turntable");
    crank = addGear(1,"Crank");    crank.contributesToCycle = false;
  
    // These are optional
    Gear  anchorTable = addGear(2,"AnchorTable");
    Gear  anchorHub = addGear(3,"AnchorHub"); anchorHub.contributesToCycle = false;
    Gear  orbit = addGear(4,"Orbit");
  
    orbit.isMoving = true;
  
    // Setup gear relationships and mount points here...
    crank.mount(crankRail, 0);
    turnTable.mount(discPoint, 0);
    crank.snugTo(turnTable);
    crank.meshTo(turnTable);
  
    anchorTable.mount(anchorRail, .315);
    anchorTable.snugTo(crank);
    anchorTable.meshTo(crank);

    anchorHub.stackTo(anchorTable);
    anchorHub.isFixed = true;

    orbit.mount(anchorTable,0);
    orbit.snugTo(anchorHub);
    orbit.meshTo(anchorHub);
  
    // Setup Pen
    slidePoint = addMP(0, "SP", pivotRail);
    anchorPoint = addMP(1, "AP", orbit);
    cRod = addCR(slidePoint, anchorPoint);
    penMount = addMP(2, "EX", cRod);
    penRig = new PenRig(4.0, (-PI/2), penMount);
    break;

  case 3:// 2 pen rails, variation A
    pivotRail = rails.get(1);
    Channel aRail = rails.get(10);
    Channel bRail = rails.get(7);
    turnTable = addGear(0,"Turntable");
    Gear aGear = addGear(1,"A");
    Gear bGear = addGear(2,"B");

    turnTable.mount(discPoint, 0);
    aGear.mount(aRail, 0.5);
    aGear.snugTo(turnTable);
    aGear.meshTo(turnTable);

    bGear.mount(bRail, 0.5);
    bGear.snugTo(turnTable);
    bGear.meshTo(turnTable);

    slidePoint = addMP(0, "SP", aGear);
    anchorPoint = addMP(1, "AP", bGear);
    cRod = addCR(slidePoint, anchorPoint);

    MountPoint slidePoint2 = addMP(2, "SP2", pivotRail);
    MountPoint anchorPoint2 = addMP(3, "AP2", cRod);
    ConnectingRod cRod2 = addCR(slidePoint2, anchorPoint2);
    penMount = addMP(4,"EX",cRod2);
    penRig = new PenRig(4.0, (-PI/2), penMount);

    break;

  case 4: // 2 pen rails, variation B
    pivotRail = rails.get(1);
    aRail = rails.get(10);
    bRail = rails.get(7);
    turnTable = addGear(0,"TurnTable");
    aGear = addGear(1,"A");
    bGear = addGear(2,"B");

    turnTable.mount(discPoint, 0);
    aGear.mount(aRail, 0.5);
    aGear.snugTo(turnTable);
    aGear.meshTo(turnTable);

    bGear.mount(bRail, 0.5);
    bGear.snugTo(turnTable);
    bGear.meshTo(turnTable);

    slidePoint = addMP(0, "SP", pivotRail);
    anchorPoint = addMP(1, "AP", bGear);
    cRod = addCR(slidePoint, anchorPoint);

    slidePoint2 = addMP(2, "SP2", aGear);
    anchorPoint2 = addMP(3, "AP2", cRod);
    cRod2 = addCR(anchorPoint2, slidePoint2);

    penMount = addMP(4, "EX", cRod2);

    penRig = new PenRig(3.0, (-PI/2), penMount);

    break;

  case 5: // 3 pen rails
    pivotRail = rails.get(1);
    aRail = rails.get(10);
    bRail = rails.get(7);
    turnTable = addGear(0,"Turntable");
    aGear = addGear(1,"A");
    bGear = addGear(2,"B");

    turnTable.mount(discPoint, 0);
    aGear.mount(aRail, 0.5);
    aGear.snugTo(turnTable);
    aGear.meshTo(turnTable);

    bGear.mount(bRail, 0.5);
    bGear.snugTo(turnTable);
    bGear.meshTo(turnTable);

    slidePoint = addMP(0, "SP", pivotRail);
    anchorPoint = addMP(1, "AP", bGear);
    cRod = addCR(slidePoint, anchorPoint);

    slidePoint2 = addMP(2, "SP2", aGear);
    anchorPoint2 = addMP(3, "AP2", pivotRail);
    cRod2 = addCR(slidePoint2, anchorPoint2);

    MountPoint slidePoint3 = addMP(4, "SP3", cRod2);
    MountPoint anchorPoint3 = addMP(5, "SA3", cRod);
    ConnectingRod cRod3 = addCR(anchorPoint3, slidePoint3);
    penMount = addMP(6, "EX", cRod3);
    
    penRig = new PenRig(2.0, (-PI/2), penMount);

    break;    
  case 6: // orbiting gear with rotating fulcrum (#1 and #2 combined)
    crankRail = rails.get(9);
    anchorRail = rails.get(4);
    // pivotRail = rails.get(1);
    Channel fulcrumCrankRail = rails.get(1);
    Channel fulcrumGearRail = rails.get(0);
    
    // Always need these...
    turnTable = addGear(0,"Turntable");
    crank = addGear(1,"Crank");                            crank.contributesToCycle = false;
  
    // These are optional
    anchorTable = addGear(2,"AnchorTable");
    anchorHub = addGear(3,"AnchorHub");                    anchorHub.contributesToCycle = false;
    orbit = addGear(4,"Orbit");
  
    Gear  fulcrumCrank = addGear(5,"FulcrumCrank");        fulcrumCrank.contributesToCycle = false;       
    fulcrumGear = addGear(6,"FulcrumOrbit");
  
    orbit.isMoving = true;
  
    // Setup gear relationships and mount points here...
    crank.mount(crankRail, 0);
    turnTable.mount(discPoint, 0);
    crank.snugTo(turnTable);
    crank.meshTo(turnTable);
  
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
    slidePoint = addMP(0, "SP", fulcrumGear);
    anchorPoint = addMP(1, "AP", orbit);
    cRod = addCR(slidePoint, anchorPoint);
    penMount = addMP(2, "EX", cRod);
    penRig = new PenRig(4.0, (-PI/2), penMount);

    break;

  }
  turnTable.showMount = false;
  
}



void draw() 
{

    background(darkTheme? 128 : 255);

  // Crank the machine a few times, based on current passesPerFrame - this generates new gear positions and drawing output
  for (int p = 0; p < passesPerFrame; ++p) {
    if (isMoving) {
      myFrameCount += 1;
      turnTable.crank(myFrameCount*crankSpeed); // The turntable is always the root of the propulsion chain, since it is the only required gear.

      // work out coords on unrotated paper
      PVector nib = penRig.getPosition();
      float dx = nib.x - pCenterX*inchesToPoints;
      float dy = nib.y - pCenterY*inchesToPoints;
      float a = atan2(dy, dx);
      float l = sqrt(dx*dx + dy*dy);
      float px = paperWidth/2 + cos(a-turnTable.rotation)*l*paperScale;
      float py = paperWidth/2 + sin(a-turnTable.rotation)*l*paperScale;
    
      paper.beginDraw();
      if (!isStarted) {
        paper.clear();
        paper.smooth(8);
        paper.noFill();
        paper.stroke(penColor);
        paper.strokeJoin(ROUND);
        paper.strokeCap(ROUND);
        paper.strokeWeight(penWidth);
        // paper.rect(10, 10, paperWidth-20, paperWidth-20);
        isStarted = true;
      } else if (!penRaised) {
        paper.line(lastPX, lastPY, px, py);
      }
      paper.endDraw();
      lastPX = px;
      lastPY = py;
      penRaised = false;
      if (myLastFrame != -1 && myFrameCount >= myLastFrame) {
        myLastFrame = -1;
        passesPerFrame = 1;
        isMoving = false;
        isRecording = false;
        nextTween();
        break;
      }
    }
  }

  // Draw the machine onscreen in it's current state
  pushMatrix();
    fill(200);
    noStroke();

    float logoScale = inchesToPoints/72.0;
    if (darkTheme)
      blendMode(ADD);
    image(titlePic, 0, height-titlePic.height*logoScale, titlePic.width*logoScale, titlePic.height*logoScale);
    if (darkTheme)
      blendMode(BLEND);
    for (Channel ch : rails) {
       ch.draw();
    }
  
    // discPoint.draw();
  
    for (Gear g : activeGears) {
      g.draw();
    }
  
    penRig.draw();
  
    pushMatrix();
      translate(pCenterX*inchesToPoints, pCenterY*inchesToPoints);
      rotate(turnTable.rotation);
      image(paper, -paperWidth/(2*paperScale), -paperWidth/(2*paperScale), paperWidth/paperScale, paperWidth/paperScale);
    popMatrix();

    helpDraw(); // draw help if needed

  popMatrix();
  if (isMoving && isRecording) {
    recordCtr++;
    saveSnapshotAs("record_" + df.format(recordCtr) + ".png");
  }
}

boolean isShifting = false;

void keyReleased() {
  if (key == CODED && keyCode == SHIFT) {
    isShifting = false;
  }
}

void keyPressed() {
  switch (key) {
   case ' ':
      isMoving = !isMoving;
      myLastFrame = -1;
      println("Current cycle length: " + myFrameCount / (TWO_PI/crankSpeed));

      break;
   case '?':
     toggleHelp();
     break;
   case '0':
     isMoving = false;
     passesPerFrame = 0;
     myLastFrame = -1;
     println("Current cycle length: " + myFrameCount / (TWO_PI/crankSpeed));
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
      passesPerFrame = int(map((key-'0'),2,9,10,360));
      isMoving = true;
      break;
   case 'a':
   case 'b':
   case 'c':
   case 'd':
   case 'e':
   case 'f':
   case 'g':
     deselect();
     drawingSetup(key - 'a', false);
     break;
   case 'X':
   case 'x':
     clearPaper();
     break;
  case 'p':
    // Swap pen mounts - need visual feedback
    break;
  case 's':
    saveSnapshot("snapshot_");
    break;
  case '~':
  case '`':
    completeDrawing();
    break;
  case 'M':
    measureGears();
    break;
  case 'T':
    saveTweenSnapshot();
    break;
  case 'S':
    beginTweening();
    break;
  case 'R':
  case 'r':
    isRecording = !isRecording;
    println("Recording is " + (isRecording? "ON" : "OFF"));
    break;
  case 'H':
    toggleHiresmode();
    break;
  case '[':
    advancePenColor(-1);
    break;
  case ']':
    advancePenColor(1);
    break;
  case '<':
    advancePenWidth(-1);
    break;
  case '>':
    advancePenWidth(1);
    break;
  case '/':
    invertConnectingRod();
    break;
  case '+':
  case '-':
  case '=':
    int direction = (key == '+' || key == '='? 1 : -1);
    nudge(direction, keyCode);
    break;
  case CODED:
    switch (keyCode) {
    case UP:
    case DOWN:
    case LEFT:
    case RIGHT:
      direction = (keyCode == RIGHT || keyCode == UP? 1 : -1);
      nudge(direction, keyCode);
      break;
    case SHIFT:
      isShifting = true;
      break;
    default:
     println("KeyCode pressed: " + (0 + keyCode));
     break;
    }
    break;
   default:
     println("Key pressed: " + (0 + key));
     break;
  }
}

void mousePressed() 
{
  deselect();

  for (MountPoint mp : activeMountPoints) {
    if (mp.isClicked(mouseX, mouseY)) {
      mp.select();
      selectedObject= mp;
      return;
    }
  }
  
  if (penRig.isClicked(mouseX, mouseY)) {
    penRig.select();
    selectedObject= penRig;
    return;
  }

  for (ConnectingRod cr : activeConnectingRods) {
    if (cr.isClicked(mouseX, mouseY)) {
      cr.select();
      selectedObject= cr;
      return;
    }
  }

  for (Gear g : activeGears) {
    if (g.isClicked(mouseX, mouseY)) {
        deselect();
        g.select();
        selectedObject = g;
    }
  }
}


