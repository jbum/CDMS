
interface Channel {
  PVector getPosition(float r);
  void draw();
  void snugTo(Gear moveable, Gear fixed); // position moveable gear on this channel so it is snug to fixed gear, not needed for all channels
}

interface Selectable {
  void select();
  void unselect();
  void nudge(int direction, int keycode);
}

static final float kMPDefaultRadius = inchesToPoints * 12/72.0;
static final float kMPSlideRadius = inchesToPoints * 20/72.0;
static final float kGearMountRadius = inchesToPoints * 12/72.0;
// static final float kGearNotchWidth = inchesToPoints * 16.5/72.0;
static final float kGearNotchWidth = 5 * mmToInches * inchesToPoints;
static final float kGearNotchHeightMaj = 5 * mmToInches * inchesToPoints;
static final float kGearNotchHeightMin = 3.5 * mmToInches * inchesToPoints;
static final float kGearLabelStart = 0.5*inchesToPoints;
static final float kGearLabelIncr = 0.5*inchesToPoints;
static final float kCRLabelIncr = 0.5*inchesToPoints;
static final float kCRNotchIncr = 0.25*inchesToPoints;
static final float kCRNotchStart = 0.75*inchesToPoints;
static final float kCRLabelStart = 1*inchesToPoints;
static final float kPenLabelStart = 4.75*inchesToPoints;
static final float kPenLabelIncr = -0.5*inchesToPoints;
static final float kPenNotchIncr = -0.25*inchesToPoints;
static final float kPaperRad = 4.625*inchesToPoints;

class MountPoint implements Channel, Selectable {
  Channel itsChannel = null;
  float itsMountLength;
  int    setupIdx;
  float x, y, radius=kMPDefaultRadius;
  String typeStr = "MP";
  boolean isFixed = false;
  boolean selected = false;
  
  MountPoint(String typeStr, float x, float y) {
    this.typeStr = typeStr;
    this.itsChannel = null;
    this.itsMountLength = 0;
    this.isFixed = true;
    this.setupIdx = -1; // fixed
    this.x = x*inchesToPoints;
    this.y = y*inchesToPoints;
  }

  MountPoint(String typeStr, Channel ch, float mr, int setupIdx) {
    this.typeStr = typeStr;
    this.itsChannel = ch;
    this.itsMountLength = mr;
    this.setupIdx = setupIdx;
    PVector pt = ch.getPosition(mr);
    this.x = pt.x;
    this.y = pt.y;
  }
  
  int chooseBestDirection(int direction, int keycode, float incr) 
  {
    PVector pNeg = itsChannel.getPosition(itsMountLength-incr);
    PVector pPos = itsChannel.getPosition(itsMountLength+incr);
    switch (keycode) {
      case RIGHT:
        return (pPos.x >= pNeg.x)? 1 : -1; 
      case LEFT:
        return (pPos.x <= pNeg.x)? 1 : -1; 
      case UP:
        return (pPos.y <= pNeg.y)? 1 : -1; 
      case DOWN:
        return (pPos.y >= pNeg.y)? 1 : -1; 
      default:
        return direction;      
    }
  }
  
  void nudge(int direction, int keycode) {
    float amt, mn=0, mx=1;
    if (itsChannel instanceof ConnectingRod) {
      amt = 0.125;
      mn = 0.5; 
      mx = 29;
    } else if (itsChannel instanceof Gear) {
      amt = 0.125;
      mn = 0.75;
      mx = ((Gear) itsChannel).radius/(kGearLabelIncr) - 1;
    } else {
      amt = 0.01;
    }
    direction = chooseBestDirection(direction, keycode, amt);
    amt *= direction;
    itsMountLength += amt;
    itsMountLength = constrain(itsMountLength, mn, mx);
    if (setupIdx >= 0) {
      setupMounts[setupMode][setupIdx] = itsMountLength;
    }
  }
  
  float getDistance(float v1, float v2) {
    PVector src = itsChannel.getPosition(v1);
    PVector dst = itsChannel.getPosition(v2);
    return dist(src.x, src.y, dst.x, dst.y);
  }
  
  void unselect() {
    selected = false;
  }
  
  void select() {
    selected = true;
  }

  boolean isClicked(int mx, int my) {
    PVector p = this.getPosition();
    return dist(mx, my, p.x, p.y) <= this.radius;
  }

  PVector getPosition() {
    return getPosition(0.0);
  }

  PVector getPosition(float r) {
    if (itsChannel != null) {
      return itsChannel.getPosition(itsMountLength);
    } else {
      return new PVector(x,y);
    }
  }

  void snugTo(Gear moveable, Gear fixed) { // not meaningful
  }
  
  void draw() {
    PVector p = getPosition();
    if (itsChannel instanceof ConnectingRod) {
      itsChannel.draw();
    } 
    if (selected) {
      fill(180,192);
      stroke(50);
    } else {
      fill(180,192);
      stroke(100);
    }
    strokeWeight(selected? 4 : 2);
    ellipse(p.x, p.y, this.radius, this.radius);
  }
}

class ConnectingRod implements Channel, Selectable {
  MountPoint itsSlide = null;
  MountPoint itsAnchor = null;
  float armAngle = 0;
  int rodNbr = 0;
  boolean selected=false;
  boolean isInverted = false;

  ConnectingRod(MountPoint itsSlide, MountPoint itsAnchor, int rodNbr)
  {
    this.rodNbr = rodNbr;
    this.itsSlide = itsSlide;
    itsSlide.radius = kMPSlideRadius;
    this.itsAnchor = itsAnchor;
    
    if (setupInversions[setupMode][rodNbr])
      invert();
     
  }
  
  PVector getPosition(float r) {
    PVector ap = itsAnchor.getPosition();
    PVector sp = itsSlide.getPosition();
    armAngle = atan2(sp.y - ap.y, sp.x - ap.x);
    float d = notchToDist(r);
    return new PVector(ap.x + cos(armAngle)*d, ap.y + sin(armAngle)*d);
  }  

  void snugTo(Gear moveable, Gear fixed) {
    // not relevant for connecting rods
  }

  void unselect() {
    selected = false;
  }
  
  void select() {
    selected = true;
  }
  
  void invert() {
    this.isInverted = !this.isInverted;
    setupInversions[setupMode][rodNbr] = this.isInverted;

    MountPoint tmp = itsAnchor;
    itsAnchor = itsSlide;
    itsSlide = tmp;
    itsAnchor.radius = kMPDefaultRadius;
    itsSlide.radius = kMPSlideRadius;
    if (penRig != null && penRig.itsRod == this) {
      penRig.angle += 180;
      if (penRig.angle > 360)
        penRig.angle -= 360;
      setupPens[setupMode][1] = penRig.angle;
    }
    doSaveSetup();
  }
  
  void nudge(int direction, int kc) {
    if (kc == UP || kc == DOWN) {
      this.invert();
    }
    else {
      if (penRig.itsRod == this) {
        penRig.itsMP.nudge(direction, kc);
      }
    }
  }

  boolean isClicked(int mx, int my) 
  {
    PVector ap = itsAnchor.getPosition();
    PVector sp = itsSlide.getPosition();

    // mx,my, ap, ep522 293 546.1399 168.98767   492.651 451.97696
    int gr = 5;
    return (mx > min(ap.x-gr,sp.x-gr) && mx < max(ap.x+gr,sp.x+gr) &&
            my > min(ap.y-gr,sp.y-gr) && my < max(ap.y+gr,sp.y+gr) &&
           abs(atan2(my-sp.y,mx-sp.x) - atan2(ap.y-sp.y,ap.x-sp.x)) < radians(10)); 
  }

  float notchToDist(float n) {
    return kCRLabelStart+(n-1)*kCRLabelIncr;
  }

  float distToNotch(float d) {
    return 1 + (d - kCRLabelStart)/kCRLabelIncr;
  }

 
  void draw() {
    PVector ap = itsAnchor.getPosition();
    PVector sp = itsSlide.getPosition();


    itsSlide.draw();
    itsAnchor.draw();

    noFill();
    int shade = selected? 100 : 200;
    int alfa = selected? 192 : 192;
    stroke(shade, alfa);
    strokeWeight(.33*inchesToPoints);
    armAngle = atan2(sp.y - ap.y, sp.x - ap.x);
    // println("Drawing arm " + ap.x/inchesToPoints +" " + ap.y/inchesToPoints + " --> " + sp.x/inchesToPoints + " " + sp.y/inchesToPoints);
    float L = 18 * inchesToPoints;
    line(ap.x,ap.y, ap.x+cos(armAngle)*L, ap.y+sin(armAngle)*L);
    
    stroke(100,100,100,128);
    fill(100,100,100);
    strokeWeight(0.5);
    // float notchOffset = 0.75*inchesToPoints;
    textFont(nFont);
    textAlign(CENTER);
    pushMatrix();
      translate(sp.x,sp.y);
      rotate(atan2(ap.y-sp.y,ap.x-sp.x));
      float ln = dist(ap.x,ap.y,sp.x,sp.y);
      for (int i = 0; i < 29*2; ++i) {
        float x = ln-(kCRNotchStart + kCRNotchIncr*i);
        line(x, 6, x, -(6+(i % 2 == 1? 2 : 0)));
        if (i % 2 == 1) {
          text(""+int(1+i/2),x,8);
        }
      }
    popMatrix();
  }
}

class PenRig implements Selectable {
  float len;
  float angle; // expressed in degrees
  boolean selected = false;
  ConnectingRod itsRod;
  MountPoint itsMP;
  int lastDirection = -1; // these are used to avoid rotational wierdness with manipulations
  long lastRotation = -1;
  int lastKey = -1;


  PenRig(float len, float angle, MountPoint itsMP) {
    this.len = len; // in pen notch units
    this.angle = angle;
    this.itsRod = (ConnectingRod) itsMP.itsChannel;
    this.itsMP = itsMP;

    PVector ap = itsMP.getPosition();
    PVector ep = this.getPosition();
  }

  float notchToDist(float n) {
    return kPenLabelStart+(n-1)*kPenLabelIncr;
  }

  float distToNotch(float d) {
    return 1 + (d - kPenLabelStart)/kPenLabelIncr;
  }

  PVector getPosition() {
    PVector ap = itsMP.getPosition();
    float d = notchToDist(this.len);
    float rangle = radians(this.angle);
    return new PVector(ap.x + cos(itsRod.armAngle + rangle)*d, ap.y + sin(itsRod.armAngle + rangle)*d);
  }

  PVector getPosition(float len, float angle) {
    PVector ap = itsMP.getPosition();
    float d = notchToDist(len);
    float rangle = radians(angle);
    return new PVector(ap.x + cos(itsRod.armAngle + rangle)*d, ap.y + sin(itsRod.armAngle + rangle)*d);
  }

  
  boolean isClicked(int mx, int my) 
  {
    PVector ap = itsMP.getPosition();
    PVector ep = this.getPosition();

    float a = atan2(ap.y-ep.y,ap.x-ep.x);
    float d = 6*inchesToPoints;
    ap.x = ep.x + cos(a)*d;
    ap.y = ep.y + sin(a)*d;

    int gr = 5;
    return (mx > min(ap.x-gr,ep.x-gr) && mx < max(ap.x+gr,ep.x+gr) &&
            my > min(ap.y-gr,ep.y-gr) && my < max(ap.y+gr,ep.y+gr) &&
           abs(atan2(my-ep.y,mx-ep.x) - atan2(ap.y-ep.y,ap.x-ep.x)) < radians(10)); 
  }
  
  void unselect() {
    selected = false;
  }
  
  void select() {
    selected = true;
  }


  int chooseBestDirection(int direction, int keycode, float lenIncr, float angIncr) 
  {
    if (abs(angIncr) > abs(lenIncr) && lastRotation != -1 && (millis()-lastRotation) < 10000) {
      return lastDirection * (lastKey == keycode? 1 : -1);
    } 

    PVector pNeg = getPosition(len -lenIncr, angle-angIncr);
    PVector pPos = getPosition(len +lenIncr, angle+angIncr);

    switch (keycode) {
      case RIGHT:
        return (pPos.x >= pNeg.x)? 1 : -1; 
      case LEFT:
        return (pPos.x <= pNeg.x)? 1 : -1; 
      case UP:
        return (pPos.y <= pNeg.y)? 1 : -1; 
      case DOWN:
        return (pPos.y >= pNeg.y)? 1 : -1; 
      default:
        return direction;      
    }
  }
  
  void nudge(int direction, int kc) {
    float angIncr = 0, lenIncr = 0;
    if (kc == RIGHT || kc == LEFT) {
      angIncr = 5;
    } else {
      lenIncr = 0.125;
    }
    direction = chooseBestDirection(direction, kc, lenIncr, angIncr);
    
    if (abs(angIncr) > abs(lenIncr)) {
      lastRotation = millis();
    }
    lastDirection = direction;
    lastKey = kc;
    
    this.angle += angIncr*direction;
    if (this.angle > 180) {
      this.angle -= 360;
    } else if (this.angle <= -180) {
      this.angle += 360;
    }
    setupPens[setupMode][1] = this.angle;
    this.len += lenIncr*direction;
    this.len = constrain(this.len, 1, 8);
    setupPens[setupMode][0] = this.len;
  }
  
  void draw() {
    itsMP.draw();
    PVector ap = itsMP.getPosition();
    PVector ep = this.getPosition();

    float a = atan2(ap.y-ep.y,ap.x-ep.x);
    float d = 6*inchesToPoints;
    ap.x = ep.x + cos(a)*d;
    ap.y = ep.y + sin(a)*d;

    noFill();
    if (selected)
      stroke(penColor,128);
    else
      stroke(penColor,64);
    strokeWeight(.33*inchesToPoints);
    line(ap.x, ap.y, ep.x, ep.y);
  
    float nibRad = inchesToPoints * 0.111;
  
    strokeWeight(0.5);
    pushMatrix();
      translate(ep.x,ep.y);
      rotate(atan2(ap.y-ep.y,ap.x-ep.x));
      fill(255);
      ellipse(0,0,nibRad,nibRad);
      noFill();
      stroke(192);
      line(-nibRad,0,nibRad,0);
      line(0,nibRad,0,-nibRad);
      
      textFont(nFont);
      textAlign(CENTER);
      fill(penColor);
      noStroke();
      ellipse(0,0,penWidth/2, penWidth/2);

      stroke(96);
      fill(64);
      for (int i = 0; i < 15; ++i) {
        float x = notchToDist(1+i/2.0);
        line(x, 6, x, -(6+(i % 2 == 0? 2 : 0)));
        if (i % 2 == 0) {
          text(""+int(1+i/2),x,8);
        }
      }
      popMatrix();


  }
}

class LineRail implements Channel {
  float x1,y1, x2,y2;
  LineRail(float x1, float y1, float x2, float  y2) {
    this.x1 = x1*inchesToPoints;
    this.y1 = y1*inchesToPoints;
    this.x2 = x2*inchesToPoints;
    this.y2 = y2*inchesToPoints;
  }
  PVector getPosition(float r) {
    return new PVector(x1+(x2-x1)*r, y1+(y2-y1)*r);
  }  

  void draw() {
    noFill();
    stroke(110);
    strokeWeight(.23*inchesToPoints);

    line(x1,y1, x2,y2);
  }
  
  void snugTo(Gear moveable, Gear fixed) {
    float dx1 = x1-fixed.x;
    float dy1 = y1-fixed.y;
    float dx2 = x2-fixed.x;
    float dy2 = y2-fixed.y;
    float a1 = atan2(dy1,dx1);
    float a2 = atan2(dy2,dx2);
    float d1 = dist(x1,y1,fixed.x,fixed.y);
    float d2 = dist(x2,y2,fixed.x,fixed.y);
    float adiff = abs(a1-a2);
    float r = moveable.radius+fixed.radius+meshGap;
    float mountRatio;
    if (adiff > TWO_PI)
      adiff -= TWO_PI;
    if (adiff < .01) {  // if rail is perpendicular to fixed circle
      mountRatio = (r-d1)/(d2-d1);
      // find position on line (if any) which corresponds to two radii
    } else if ( abs(x2-x1) < .01 ) {
      float m = 0;
      float c = (-m * y1 + x1);
      float aprim = (1 + m*m);
      float bprim = 2 * m * (c - fixed.x) - 2 * fixed.y;
      float cprim = fixed.y * fixed.y + (c - fixed.x) * (c - fixed.x) - r * r;
      float delta = bprim * bprim - 4*aprim*cprim;
      float my1 = (-bprim + sqrt(delta)) / (2 * aprim);
      float mx1 = m * my1 + c;
      float my2 = (-bprim - sqrt(delta)) / (2 * aprim); // use this if it's better
      float mx2 = m * my2 + c;
      if (my1 < min(y1,y2) || my1 > max(y1,y2) || 
          dist(moveable.x,moveable.y,mx2,my2) < dist(moveable.x,moveable.y,mx1,mx2)) {
        mx1 = mx2;
        my1 = my2;
      } 
      if (delta < 0) {
        mountRatio = -1;
      } else {
        mountRatio = dist(x1,y1,mx1,my1)/dist(x1,y1,x2,y2);
      }
    } else { // we likely have a gear on one of the lines on the left
      // given the line formed by x1,y1 x2,y2, find the two spots which are desiredRadius from fixed center.
      float m = (y2-y1)/(x2-x1);
      float c = (-m * x1 + y1);
      float aprim = (1 + m*m);
      float bprim = 2 * m * (c - fixed.y) - 2 * fixed.x;
      float cprim = fixed.x * fixed.x + (c - fixed.y) * (c - fixed.y) - r * r;
      float delta = bprim * bprim - 4*aprim*cprim;
      float mx1 = (-bprim + sqrt(delta)) / (2 * aprim);
      float my1 = m * mx1 + c;
      float mx2 = (-bprim - sqrt(delta)) / (2 * aprim); // use this if it's better
      float my2 = m * mx2 + c;
      if (mx1 < min(x1,x2) || mx1 > max(x1,x2) || my1 < min(y1,y2) || my1 > max(y1,y2) ||
          dist(moveable.x,moveable.y,mx2,my2) < dist(moveable.x,moveable.y,mx1,mx2)) {
        mx1 = mx2;
        my1 = my2;
      }
      if (delta < 0) {
        mountRatio = -1;
      } else {
        mountRatio = dist(x1,y1,mx1,my1)/dist(x1,y1,x2,y2);
      }
    }
    if (mountRatio < 0 || mountRatio > 1 || mountRatio == NaN) {
      loadError = 1;
      mountRatio = 0;
    }
    mountRatio = constrain(mountRatio,0,1);
    moveable.mount(this,mountRatio);
  }
}

class ArcRail implements Channel {
  float cx,cy, rad, begAngle, endAngle;
  ArcRail(float cx, float cy, float rad, float begAngle, float  endAngle) {
    this.cx = cx*inchesToPoints;
    this.cy = cy*inchesToPoints;
    this.rad = rad*inchesToPoints;
    this.begAngle = begAngle;
    this.endAngle = endAngle;  
  }

  PVector getPosition(float r) {
    float a = begAngle + (endAngle - begAngle)*r;
    return new PVector(cx+cos(a)*rad, cy+sin(a)*rad);
  }  

//  fixed = 15.017775 6.61 1.5221801
//  moveable = 16.518276 2.237212 3.0443602
//  rail = 8.91 3.9100003 7.79
//  angles = -24.999998 15.0
//  desired r = 4.625595
//  d = 6.6779423
//  i1 12.791063 2.2343254 ang -23.352594
//  i2 16.517643 2.2343254 ang -12.421739


  void snugTo(Gear moveable, Gear fixed) { // get the movable gear mounted on this rail snug to the fixed gear

    // The fixed gear is surrounded by an imaginary circle which is the correct distance (r) away.
    // We need to intersect this with our arcRail circle, and find the intersection point which lies on the arcrail.
    // Mesh point 
    // https://gsamaras.wordpress.com/code/determine-where-two-circles-intersect-c/

//    println("Snug arcrail");
//    println("  fixed = " + fixed.x/72 + " " + fixed.y/72 + " " + fixed.radius/72);
//    println("  moveable = " + moveable.x/72 + " " + moveable.y/72 + " " + moveable.radius/72);
//    println("  rail = " + cx/72 + " " + cy/72 + " " + rad/72);
//    println("  angles = " + degrees(begAngle) + " " + degrees(endAngle));

   float x1 = fixed.x;
   float y1 = fixed.y;
   float r1 = moveable.radius+fixed.radius+meshGap;
   float x2 = this.cx;
   float y2 = this.cy;
   float r2 = this.rad;

    float d = dist(x1,y1,x2,y2);
    
    if (d > r1+r2) {
      loadError = 1;
      return;
    } else if (abs(d) < .01 && abs(r1-r2) < .01) {
      loadError = 1;
      return;
    } else if (d + min(r1,r2) < max(r1,r2)) {
      loadError = 1;
      return;
    }
    float a = (r1*r1 - r2*r2 + d*d) / (2*d);
    float h = sqrt(r1*r1 - a*a);
    PVector p2 = new PVector( x1 + (a * (x2 - x1)) / d,
                              y1 + (a * (y2 - y1)) / d);
                              
    // these are our two intersection points (which may or may not fall on the arc)
    PVector i1 = new PVector( p2.x + (h * (y2 - y1))/ d,
                              p2.y + (h * (x2 - x1))/ d);
    PVector i2 = new PVector( p2.x - (h * (y2 - y1))/ d,
                              p2.y + (h * (x2 - x1))/ d);

    PVector best = i2;
    float ma = atan2(best.y-cy,best.x-cx);
    if (ma < begAngle || ma > endAngle) {
      best = i1;
      ma = atan2(best.y-cy,best.x-cx);
      if (ma < begAngle || ma > endAngle) {
        loadError = 1;
        return;
      }
    }

    float mountRatio = (ma-begAngle)/(endAngle-begAngle);
    if (mountRatio < 0 || mountRatio > 1)
      loadError = 1;
    moveable.mount(this, mountRatio);
  }

  void draw() {
    noFill();
    stroke(110);
    strokeWeight(.23*inchesToPoints);
    arc(cx, cy, rad, rad, begAngle, endAngle);
  }
}


int[] rgTeeth = { // regular gears
  30, 32, 34, 36, 40, 48, 50, 58, 60, 66, 72, 74, 80, 90, 94, 98, 100, 108, 
 };
int [] ttTeeth = { // turntable gears
   120, 144, 150
};

class GearSetup {
  float notchStart;
  float notchEnd;
  int nbrLabels;
  int teeth;
  GearSetup(int teeth, float notchStart, float notchEnd, int nbrLabels)
  {
    this.teeth = teeth;
    this.notchStart = notchStart * inchesToPoints;
    this.notchEnd = notchEnd * inchesToPoints;
    this.nbrLabels = nbrLabels;
  } 
}

HashMap<Integer, GearSetup> gearSetups;

void gearInit()
{
  gearSetups = new HashMap<Integer, GearSetup>();
  gearSetups.put(108, new GearSetup(108, 0.4375,  3.0,     6));
  gearSetups.put(100, new GearSetup(100, 0.40625, 2.8125,  5));
  gearSetups.put( 98, new GearSetup( 98, 0.4375,  2.8125,  5));
  gearSetups.put( 94, new GearSetup( 94, 0.375,   2.625,   5));
  gearSetups.put( 90, new GearSetup( 90, 0.40625, 2.5,     5));
  gearSetups.put( 80, new GearSetup( 80, 0.40625, 2.25,    4));
  gearSetups.put( 74, new GearSetup( 74, 0.40625, 2.031,   4));
  gearSetups.put( 72, new GearSetup( 72, 0.375,   2.0,     4));
  gearSetups.put( 66, new GearSetup( 66, 0.375,   1.6875,  3));
  gearSetups.put( 60, new GearSetup( 60, 0.3125,  1.625,   3));
  gearSetups.put( 58, new GearSetup( 58, 0.3125,  1.5625,  3));
  gearSetups.put( 50, new GearSetup( 50, 0.25,    1.3125,  2));      // notch joins axel
  gearSetups.put( 48, new GearSetup( 48, 0.375,   1.25,    2));
  gearSetups.put( 40, new GearSetup( 40, 0.25,    1.0,     2));      // notch joins axel
  gearSetups.put( 36, new GearSetup( 36, 0.3125,  0.968,   1));
  gearSetups.put( 34, new GearSetup( 34, 0.3125,  0.84375, 1));
  gearSetups.put( 32, new GearSetup( 32, 0.3125,  0.8125,  1));
  gearSetups.put( 30, new GearSetup( 30, 0.3125,  0.75,    1));
}

class Gear implements Channel, Selectable {
  int teeth;
  int setupIdx;
  float radius;
  float rotation;
  float phase = 0;
  float  x,y;
  float mountRatio = 0;
  boolean doFill = true;
  boolean showMount = true;
  boolean isMoving = false; // gear's position is moving
  boolean isFixed = false; // gear does not rotate or move
  boolean selected = false;
  boolean contributesToCycle = true;
  ArrayList<Gear> meshGears;
  ArrayList<Gear> stackGears;
  Channel itsChannel;
  String nom;
  GearSetup itsSetup;
  
  Gear(int teeth, int setupIdx, String nom) {
    this.itsSetup = gearSetups.get(teeth);
    this.teeth = teeth;
    this.nom = nom;
    this.setupIdx = setupIdx;
    this.radius = (this.teeth*toothRadius/PI);
    this.x = 0;
    this.y = 0;
    this.phase = 0;
    meshGears = new ArrayList<Gear>();
    stackGears = new ArrayList<Gear>();
  }

  boolean isClicked(int mx, int my) {
    return dist(mx, my, this.x, this.y) <= this.radius;
  }

  void unselect() {
    selected = false;
  }
  
  void select() {
    selected = true;
  }
  
  void nudge(int direction, int keycode) {
    int gearIdx = this.setupIdx;
    int teeth, oldTeeth;
    oldTeeth = this.teeth;
    if (isShifting) {
      teeth = setupTeeth[setupMode][gearIdx] + direction;
    } else {
      teeth = findNextTeeth(setupTeeth[setupMode][gearIdx], direction);
    }
    if (teeth < 24) {
      teeth = 150;
    } else if (teeth > 150) {
      teeth = 30;
    }
    setupTeeth[setupMode][gearIdx] = teeth;
    drawingSetup(setupMode, false);
    if (loadError != 0) { // disallow invalid meshes
      // java.awt.Toolkit.getDefaultToolkit().beep();
      setupTeeth[setupMode][gearIdx] = oldTeeth;
      drawingSetup(setupMode, false);
    }
    selectedObject = activeGears.get(gearIdx);
    selectedObject.select();
  }

  
  int findNextTeeth(int teeth, int direction) {
    int[] gTeeth = (this == turnTable? ttTeeth : rgTeeth);

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
  


  PVector getPosition(float r) {
    float d = notchToDist(r); // kGearLabelStart+(r-1)*kGearLabelIncr;
    return new PVector(x+cos(this.rotation+this.phase)*d, y+sin(this.rotation+this.phase)*d);
  }  

  void meshTo(Gear parent) {
    parent.meshGears.add(this);

    // work out phase for gear meshing so teeth render interlaced
    float meshAngle = atan2(y-parent.y, x-parent.x); // angle where gears are going to touch (on parent gear)
    if (meshAngle < 0)
      meshAngle += TWO_PI;

    float iMeshAngle = meshAngle + PI;
    if (iMeshAngle >= TWO_PI)
      iMeshAngle -= TWO_PI;

    float parentMeshTooth = (meshAngle - parent.phase)*parent.teeth/TWO_PI; // tooth on parent, taking parent's phase into account
    
    // We want to insure that difference mod 1 is exactly .5 to insure a good mesh
    parentMeshTooth -= floor(parentMeshTooth);
    
    phase = (meshAngle+PI)+(parentMeshTooth+.5)*TWO_PI/teeth;
  }
  
  // Find position in our current channel which is snug to the fixed gear
  void snugTo(Gear anchor) {
    itsChannel.snugTo(this, anchor);
  }
  
  float notchToDist(float n) {
    return kGearLabelStart+(n-1)*kGearLabelIncr;
  }

  float distToNotch(float d) {
    return 1 + (d - kGearLabelStart)/kGearLabelIncr;
  }

  // Using this gear as the channel, find position for moveable gear which is snug to the fixed gear (assuming fixed gear is centered)
  void snugTo(Gear moveable, Gear fixed) {
    float d1 = 0;
    float d2 = radius;
    float d = moveable.radius+fixed.radius+meshGap;

    float mountRadDist = this.radius*d/d2;
    if (mountRadDist < 0 || mountRadDist > this.radius)
      loadError = 1;
    float mountNotch = distToNotch(mountRadDist);

    moveable.mount(this, mountNotch);
      // find position on line (if any) which corresponds to two radii
  }

  void stackTo(Gear parent) {
    parent.stackGears.add(this);
    this.x = parent.x;
    this.y = parent.y;
    this.phase = parent.phase;
  }

  void mount(Channel ch) {
    mount(ch, 0.0);
  }

  void recalcPosition() { // used for orbiting gears
    PVector pt = this.itsChannel.getPosition(this.mountRatio);
    this.x = pt.x;
    this.y = pt.y;
  }

  void mount(Channel ch, float r) {
    this.itsChannel = ch;
    this.mountRatio = r;
    PVector pt = ch.getPosition(r);
    this.x = pt.x;
    this.y = pt.y;
  }

  void crank(float pos) {
    if (!this.isFixed) {
      this.rotation = pos;
      float rTeeth = this.rotation*this.teeth;
      for (Gear mGear : meshGears) {
         mGear.crank(-(rTeeth)/mGear.teeth);
      }
      for (Gear sGear : stackGears) {
         sGear.crank(this.rotation);
      }
      if (isMoving)
       recalcPosition(); // technically only needed for orbiting gears
    }
    else {
      // this gear is fixed, but meshgears will rotate to the passed in pos
      for (Gear mGear : meshGears) {
        mGear.crank(pos + ( pos*this.teeth )/mGear.teeth);
      }
    }
  }

  void draw() {
    strokeWeight(1);
    strokeCap(ROUND);
    strokeJoin(ROUND);
    noFill();
    stroke(0);

    pushMatrix();
      translate(this.x, this.y);
      rotate(this.rotation+this.phase);

      float r1 = radius-.07*inchesToPoints;
      float r2 = radius+.07*inchesToPoints;
      float tAngle = TWO_PI/teeth;
      float tipAngle = tAngle*.1;

      if (doFill) {
        fill(220);
      } else {
       noFill();
      }
      if (selected) {
        strokeWeight(4);
        stroke(64);
      } else {
        strokeWeight(0.5);
        stroke(128);
      }
      beginShape();
      for (int i = 0; i < teeth; ++i) {
        float a1 = i*tAngle;
        float a2 = (i+.5)*tAngle;
        vertex(r2*cos(a1), r2*sin(a1));
        vertex(r2*cos(a1+tipAngle), r2*sin(a1+tipAngle));
        vertex(r1*cos(a2-tipAngle), r1*sin(a2-tipAngle));
        vertex(r1*cos(a2+tipAngle), r1*sin(a2+tipAngle));
        vertex(r2*cos(a1+tAngle-tipAngle), r2*sin(a1+tAngle-tipAngle));
        vertex(r2*cos(a1+tAngle), r2*sin(a1+tAngle));
      }
      endShape();

      if (this == turnTable) {
        noStroke();
        fill(255,192);
        beginShape();
        for (int i = 0; i < 8; ++i) {
          vertex(kPaperRad*cos(i*TWO_PI/8), kPaperRad*sin(i*TWO_PI/8));          
        }
        endShape();
      }


      strokeWeight(1);

      pushMatrix();
        translate(0, radius-20);
        fill(127);
        textFont(gFont);
        textAlign(CENTER);
        text(""+teeth, 0, 0);
        noFill();
      popMatrix();

      if (showMount) {
        noStroke();
        fill(192,128);
        ellipse(0, 0, kGearMountRadius, kGearMountRadius);

        pushMatrix();
          float notchStart, notchEnd;
          int   nbrLabels;
          if (itsSetup != null) {
            notchStart = itsSetup.notchStart;
            notchEnd = itsSetup.notchEnd;
            nbrLabels = itsSetup.nbrLabels;
          } else {
            // Make a guesstimate
            notchStart = max(radius*.1,16*seventyTwoScale);
            notchEnd = radius-max(radius*.1,8*seventyTwoScale);
            nbrLabels = 1 + int((notchEnd-notchStart-0.2*inchesToPoints)/(0.5*inchesToPoints));
          }
          textFont(nFont);
          textAlign(CENTER);

          stroke(128);
          fill(128);
          int nbrNotches = (nbrLabels)*2-1;
          for (int i = 0; i < nbrNotches; ++i) {
            float x = kGearLabelStart + i * 0.25 * inchesToPoints;
            line(x,-(i % 2 == 0? kGearNotchHeightMaj : kGearNotchHeightMin), x, (i % 2 == 0? kGearNotchHeightMaj : kGearNotchHeightMin));
            if (i % 2 == 0) {
              text((i/2)+1,x,kGearNotchHeightMaj+0.2*inchesToPoints);
            }
          }
          fill(192);
          noStroke();
          rect(notchStart, -kGearNotchWidth/2, notchEnd-notchStart, kGearNotchWidth);
        popMatrix();
      }
        

    popMatrix();
  }
}


