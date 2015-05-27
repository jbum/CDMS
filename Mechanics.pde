
interface Channel {
  PVector getPosition(float r);
  void draw();
  void snugTo(Gear moveable, Gear fixed); // position moveable gear on this channel so it is snug to fixed gear, not needed for all channels
}

class MountPoint implements Channel {
  Channel itsChannel = null;
  float itsMountRatio;
  float x, y;
  String typeStr = "MP";

  MountPoint(String typeStr, float x, float y) {
    this.typeStr = typeStr;
    this.itsChannel = null;
    this.itsMountRatio = 0;
    this.x = x*inchesToPoints;
    this.y = y*inchesToPoints;
    println(this.typeStr + " is at " + this.x/inchesToPoints + "," + this.y/inchesToPoints);
  }

  MountPoint(String typeStr, Channel ch, float mr) {
    this.typeStr = typeStr;
    this.itsChannel = ch;
    this.itsMountRatio = mr;
    PVector pt = ch.getPosition(mr);
    this.x = pt.x;
    this.y = pt.y;
    println(this.typeStr + " is at " + this.x/inchesToPoints + "," + this.y/inchesToPoints);
  }

  PVector getPosition() {
    return getPosition(0.0);
  }

  PVector getPosition(float r) {
    if (itsChannel != null) {
      return itsChannel.getPosition(itsMountRatio);
    } else {
      return new PVector(x,y);
    }
  }

  void snugTo(Gear moveable, Gear fixed) { // not meaningful
  }
  
  void draw() {
    PVector p = getPosition();
    noFill();
    stroke(180);
    strokeWeight(1);
    ellipse(p.x, p.y, 12, 12);
  }
}

class ConnectingRod implements Channel {
  MountPoint itsSlide = null;
  MountPoint itsAnchor = null;
  float armAngle = 0;

  ConnectingRod(MountPoint itsSlide, MountPoint itsAnchor)
  {
    this.itsSlide = itsSlide;
    this.itsAnchor = itsAnchor;
  }
  
  PVector getPosition(float r) {
    PVector ap = itsAnchor.getPosition();
    PVector sp = itsSlide.getPosition();
    armAngle = atan2(sp.y - ap.y, sp.x - ap.x);
    
    return new PVector(ap.x + cos(armAngle)*r, ap.y + sin(armAngle)*r);
  }  
  void snugTo(Gear moveable, Gear fixed) {
    // !! find position on arc which causes moveable to be snug to fixed
  }
  
  void draw() {
    itsSlide.draw();
    itsAnchor.draw();
    noFill();
    stroke(100,200,100);
    strokeWeight(.23*inchesToPoints);
    PVector ap = itsAnchor.getPosition();
    PVector sp = itsSlide.getPosition();
    armAngle = atan2(sp.y - ap.y, sp.x - ap.x);
    // println("Drawing arm " + ap.x/inchesToPoints +" " + ap.y/inchesToPoints + " --> " + sp.x/inchesToPoints + " " + sp.y/inchesToPoints);
    float L = 18 * inchesToPoints;
    line(ap.x,ap.y, ap.x+cos(armAngle)*L, ap.y+sin(armAngle)*L);
  }
}

class PenRig {
  float itsMountLength;
  float len;
  float angle;
  ConnectingRod itsRod;

  PenRig(float len, float angle, ConnectingRod itsRod, float ml) {
    this.len = len * inchesToPoints;
    this.angle = angle;
    this.itsRod = itsRod;
    this.itsMountLength = ml * inchesToPoints;
    PVector ap = itsRod.getPosition(this.itsMountLength);
    PVector ep = this.getPosition();
    println("Pen Extender " + ap.x/inchesToPoints +" " + ap.y/inchesToPoints + " --> " + ep.x/inchesToPoints + " " + ep.y/inchesToPoints);
  }

  PVector getPosition() {
    PVector ap = itsRod.getPosition(this.itsMountLength);
    
    return new PVector(ap.x + cos(itsRod.armAngle + this.angle)*this.len, ap.y + sin(itsRod.armAngle + this.angle)*this.len);
  }
  
  void draw() {
    itsRod.draw();
    PVector ap = itsRod.getPosition(this.itsMountLength);
    PVector ep = this.getPosition();
    noFill();
    stroke(200,150,150);
    strokeWeight(.23*inchesToPoints);
    line(ap.x, ap.y, ep.x, ep.y);
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
    stroke(200);
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
    if (adiff > TWO_PI)
      adiff -= TWO_PI;
    if (adiff < .01) {  // if rail is perpendicular to fixed circle
      moveable.mount(this, (r-d1)/(d2-d1));
      // find position on line (if any) which corresponds to two radii
    } else if ( abs(x2-x1) < .01 ) {
      println("Vertical line");
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
      println("V x1,y1 " + x1/inchesToPoints + " " + y1/inchesToPoints + " x2,y2 " + x2/inchesToPoints + " " + y2/inchesToPoints + " fixed " + fixed.x/inchesToPoints + " " + fixed.y/inchesToPoints);
      println(" aprim,bprim,cprim = " + aprim + " " + bprim + " " + cprim);
      // of the two spots which are best, and pick the one that is A) On the line and B) closest to the moveable gear's current position
      println("  mx1,mx2 " + mx1/inchesToPoints + " " + my1/inchesToPoints + " mx2,my2 " + mx2/inchesToPoints + " " + my2/inchesToPoints);
      if (my1 < min(y1,y2) || my1 > max(y1,y2) || 
          dist(moveable.x,moveable.y,mx2,my2) < dist(moveable.x,moveable.y,mx1,mx2)) {
        println("  swap");
        mx1 = mx2;
        my1 = my2;
      } 
      moveable.mount(this, dist(x1,y1,mx1,my1)/dist(x1,y1,x2,y2));
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
      println("x1,y1 " + x1/inchesToPoints + " " + y1/inchesToPoints + " x2,y2 " + x2/inchesToPoints + " " + y2/inchesToPoints);
      println(" aprim,bprim,cprim = " + aprim + " " + bprim + " " + cprim);
      // of the two spots which are best, and pick the one that is A) On the line and B) closest to the moveable gear's current position
      println("  mx1,mx2 " + mx1/inchesToPoints + " " + my1/inchesToPoints + " mx2,my2 " + mx2/inchesToPoints + " " + my2/inchesToPoints);
      if (mx1 < min(x1,x2) || mx1 > max(x1,x2) || my1 < min(y1,y2) || my1 > max(y1,y2) ||
          dist(moveable.x,moveable.y,mx2,my2) < dist(moveable.x,moveable.y,mx1,mx2)) {
        println("  swap");
        mx1 = mx2;
        my1 = my2;
      } 
      moveable.mount(this, dist(x1,y1,mx1,my1)/dist(x1,y1,x2,y2));
    }
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

  void snugTo(Gear moveable, Gear fixed) {
    // !! find position on arc which causes moveable to be snug to fixed
  }

  void draw() {
    noFill();
    stroke(200);
    strokeWeight(.23*inchesToPoints);
    arc(cx, cy, rad, rad, begAngle, endAngle);
  }
}



class Gear implements Channel { // !! implement channel
  int teeth;
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
  ArrayList<Gear> meshGears;
  ArrayList<Gear> stackGears;
  Channel itsChannel;
  
  Gear(int teeth) {
    this.teeth = teeth;
    this.radius = (this.teeth*toothRadius/PI);
    this.x = 0;
    this.y = 0;
    this.phase = 0;
    meshGears = new ArrayList<Gear>();
    stackGears = new ArrayList<Gear>();
  }

  PVector getPosition(float r) {
    return new PVector(x+cos(this.rotation)*radius*r, y+sin(this.rotation)*radius*r);
  }  

  void meshTo(Gear parent) {
    parent.meshGears.add(this);
    // !!! Determine position on channel (r) 
        // Note, if rail is a ray pointing away from center of parent, then it's an easy calcuation...
            // e.g. if starting and ending points are very close to the same angle...
            // then we find position at that angle which is correct radius away, and then figure out where that point falls on the line...
        // otherwise, we need to intersect line (or arc) with mounting circle...
    
    
    // this.mount(ch, r);
    // !! work out phase
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

  // Using this gear as the channel, find position for moveable gear which is snug to the fixed gear (assuming fixed gear is centered)
  void snugTo(Gear moveable, Gear fixed) {
    float d1 = 0;
    float d2 = radius;
    float d = moveable.radius+fixed.radius+meshGap;
    moveable.mount(this, d/d2);
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
    println("Gear " + teeth + " is at " + this.x/inchesToPoints + "," + this.y/inchesToPoints);
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
        fill(240,240,240,192);
      } else {
       noFill();
      }
      if (selected) {
        strokeWeight(4);
        stroke(64);
      } else {
        strokeWeight(1);
        stroke(0);
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
      strokeWeight(1);

      pushMatrix();
        fill(127);
        translate(0, radius-20);
        text(""+teeth, 0, 0);
        noFill();
        stroke(64);
        noFill();
      popMatrix();

      if (showMount)
        ellipse(0, 0, 12, 12);

    popMatrix();
  }
}

Gear addGear(int teeth)
{
  Gear g = new Gear(teeth);
  activeGears.add(g);
  return g;
}


