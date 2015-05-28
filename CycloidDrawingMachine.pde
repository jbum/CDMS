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
PFont  gFont, hFont, nFont;
PImage titlePic;

int[] gTeeth = { // currently unused
  30, 32, 34, 36, 40, 48, 50, 58, 60, 66, 72, 74, 80, 90, 94, 98, 100, 120, 144, 150, 151
 };

int setupMode = 0; // 0 = simple, 1 = moving pivot, 2 = orbiting gear, 3 = orbit gear + moving pivot
boolean invertPen = false;
boolean penRaised = true;

ArrayList<Gear> activeGears;
ArrayList<MountPoint> activeMountPoints;
ArrayList<Channel> rails;

Gear crank, turnTable, selectGear = null;
MountPoint slidePoint, anchorPoint, discPoint, selectMountPoint = null;
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

float lastPX = -1, lastPY = -1;
int myFrameCount = 0;


void setup() {
  size(int(bWidth*inchesToPoints)+100, int(bHeight*inchesToPoints));
  ellipseMode(RADIUS);
  gFont = createFont("EurostileBold", 32);
  hFont = createFont("EurostileBold", 18);
  nFont = loadFont("Notch-Font.vlw");
  titlePic = loadImage("title.png");
  
  activeGears = new ArrayList<Gear>();
  activeMountPoints = new ArrayList<MountPoint>();
  rails = new ArrayList<Channel>();

  // Board Setup
  
  paper = createGraphics(int(paperWidth), int(paperWidth));
  paper.beginDraw();
  paper.clear();
  paper.endDraw();

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
    {120, 100, 51},
    {150,50,100,36,40,50,75},
  };

Gear addGear(int setupIdx, String nom)
{
  Gear g = new Gear(setupTeeth[setupMode][setupIdx], setupIdx, nom);
  activeGears.add(g);
  return g;
}

MountPoint addMP(String nom, Channel chan, float attach)
{
  MountPoint mp = new MountPoint(nom, chan, attach);
  activeMountPoints.add(mp);
  return mp;
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

    slidePoint = addMP("SP", pivotRail, 0.1);
    anchorPoint = addMP("AP", crank, 0.47);
    if (invertPen)
      cRod = new ConnectingRod(anchorPoint, slidePoint);
    else
      cRod = new ConnectingRod(slidePoint, anchorPoint);
    
    penRig = new PenRig(2.0, PI/2 * (invertPen? -1 : 1), cRod, 7.4);
    break;

  case 1: // moving fulcrum & separate crank
    turnTable = addGear(0,"Turntable"); 
    crank = addGear(1,"Crank");
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

    slidePoint = addMP("SP", fulcrumGear, 0.5);
    anchorPoint = addMP("AP", anchor, 0.47);
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
    turnTable = addGear(0,"Turntable");
    crank = addGear(1,"Crank");
  
    // These are optional
    Gear  anchorTable = addGear(2,"AnchorTable");
    Gear  anchorHub = addGear(3,"AnchorHub");
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
    slidePoint = addMP("SP", pivotRail, 1-0.1027);
    anchorPoint = addMP("AP", orbit, 0.47);
    if (invertPen)
      cRod = new ConnectingRod(anchorPoint, slidePoint);
    else
      cRod = new ConnectingRod(slidePoint, anchorPoint);
    penRig = new PenRig(4.0, (-PI/2) * (invertPen? -1 : 1), cRod, 8.4);
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

    slidePoint = addMP("SP", aGear, 0.7);
    anchorPoint = addMP("AP", bGear, 0.3);
    cRod = new ConnectingRod(slidePoint, anchorPoint);

    MountPoint slidePoint2 = addMP("SP2", pivotRail, 0.8);
    MountPoint anchorPoint2 = addMP("AP2", cRod, 2.5*inchesToPoints);
    ConnectingRod cRod2;
    if (invertPen) 
      cRod2 = new ConnectingRod(anchorPoint2, slidePoint2);
    else
     cRod2 = new ConnectingRod(slidePoint2, anchorPoint2);

    penRig = new PenRig(4.0, (-PI/2) * (invertPen? -1 : 1), cRod2, 7.4);

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

    slidePoint = addMP("SP", pivotRail, 0.7);
    anchorPoint = addMP("AP", bGear, 0.3);
    cRod = new ConnectingRod(slidePoint, anchorPoint);

    slidePoint2 = addMP("SP2", aGear, 0.8);
    anchorPoint2 = addMP("AP2", cRod, 4.5*inchesToPoints);
    if (invertPen) 
     cRod2 = new ConnectingRod(slidePoint2, anchorPoint2);
    else
      cRod2 = new ConnectingRod(anchorPoint2, slidePoint2);

    penRig = new PenRig(3.0, (-PI/2) * (invertPen? -1 : 1), cRod2, 6.4);

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

    slidePoint = addMP("SP", pivotRail, 0.9);
    anchorPoint = addMP("AP", bGear, 0.4);
    cRod = new ConnectingRod(slidePoint, anchorPoint);

    slidePoint2 = addMP("SP2", aGear, 0.9);
    anchorPoint2 = addMP("AP2", pivotRail, 0.1);
    cRod2 = new ConnectingRod(slidePoint2, anchorPoint2);

    MountPoint slidePoint3 = addMP("SP3", cRod2, 9.0*inchesToPoints);
    MountPoint anchorPoint3 = addMP("SA3", cRod, 3.0*inchesToPoints);
    ConnectingRod cRod3;
    
    if (invertPen) 
     cRod3 = new ConnectingRod(slidePoint3, anchorPoint3);
    else
     cRod3 = new ConnectingRod(anchorPoint3, slidePoint3);

    penRig = new PenRig(2.0, (-PI/2) * (invertPen? -1 : 1), cRod3, 2.2);

    break;    
  case 6: // orbiting gear with rotating fulcrum (#1 and #2 combined)
    crankRail = rails.get(9);
    anchorRail = rails.get(4);
    // pivotRail = rails.get(1);
    Channel fulcrumCrankRail = rails.get(1);
    Channel fulcrumGearRail = rails.get(0);
    
    // Always need these...
    turnTable = addGear(0,"Turntable");
    crank = addGear(1,"Crank");                
  
    // These are optional
    anchorTable = addGear(2,"AnchorTable");
    anchorHub = addGear(3,"AnchorHub");
    orbit = addGear(4,"Orbit");
  
    Gear  fulcrumCrank = addGear(5,"FulcrumCrank");                
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
    slidePoint = addMP("SP", fulcrumGear, 0.5);
    anchorPoint = addMP("AP", orbit, 0.47);
    if (invertPen)
      cRod = new ConnectingRod(anchorPoint, slidePoint);
    else
      cRod = new ConnectingRod(slidePoint, anchorPoint);
    penRig = new PenRig(4.0, (-PI/2) * (invertPen? -1 : 1), cRod, 8.4);
    break;

  }
  turnTable.showMount = false;
  
}



void draw() 
{

    background(255);

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
      float px = paperWidth/2 + cos(a-turnTable.rotation)*l;
      float py = paperWidth/2 + sin(a-turnTable.rotation)*l;
    
      paper.beginDraw();
      if (!isStarted) {
        paper.clear();
        paper.smooth(8);
        paper.noFill();
        paper.stroke(0);
        paper.strokeJoin(ROUND);
        paper.strokeCap(ROUND);
        paper.strokeWeight(0.5);
        // paper.rect(10, 10, paperWidth-20, paperWidth-20);
        isStarted = true;
      } else if (!penRaised) {
        paper.line(lastPX, lastPY, px, py);
      }
      paper.endDraw();
      lastPX = px;
      lastPY = py;
      penRaised = false;
    }
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

    helpDraw(); // draw help if needed

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
     passesPerFrame = 0;
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
   case 'a':
   case 'b':
   case 'c':
   case 'd':
   case 'e':
   case 'f':
   case 'g':
     drawingSetup(key - 'a', false);
     break;
   case 'x':
     paper.beginDraw();
     paper.clear();
     paper.endDraw();
     break;
  case 'p':
    // Swap pen mounts - need visual feedback
    break;
  case 's':
    saveSnapshot();
    break;
  case '+':
  case '-':
    int direction = (key == '+'? 1 : -1);
    nudge(direction);
    break;
  case CODED:
    switch (keyCode) {
    case UP:
    case DOWN:
    case LEFT:
    case RIGHT:
      direction = (keyCode == RIGHT || keyCode == DOWN? 1 : -1);
      nudge(direction);
      break;
    }
    break;
   default:
     println("Key pressed: " + (0 + key));
     break;
  }
}

void nudge(int direction)
{
  if (selectMountPoint != null) {
    selectMountPoint.nudge(direction);
  }
  else if (selectGear != null) {
    int gearIdx = selectGear.setupIdx;
    setupTeeth[setupMode][gearIdx] += direction;
    drawingSetup(setupMode, false);
    selectGear = activeGears.get(gearIdx);
    selectGear.selected = true;
  }
}

void mousePressed() 
{
  // Unselect stuff
  if (selectGear != null) {
    selectGear.selected = false;
    selectGear = null;
  }
  if (selectMountPoint != null) {
    selectMountPoint.selected = false;
    selectMountPoint = null;
  }

  // !!! Check for selected pen mounts, rods, extensions...

  // Nothing selected? Check gears
  for (MountPoint mp : activeMountPoints) {
    PVector p = mp.getPosition();
    if (dist(mouseX, mouseY, p.x, p.y) <= mp.radius) {
      mp.doSelect();
    }
  }
  if (selectMountPoint != null)
    return;

  for (Gear g : activeGears) {
      if (dist(mouseX, mouseY, g.x, g.y) <= g.radius) {
        g.doSelect();
      }
  }
}

