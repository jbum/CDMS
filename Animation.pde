// Routines to support saving frames for stop motions

// use T to save a snapshot of the endpoint, then position pen/rods to the beginning, and hit S to save frames.

// Frames can be converted to video using

// ffmpeg2 -r 30 -y -pattern_type glob -i 'frame_*.png' -vcodec libx264 -pix_fmt yuv420p -pass 1 -s 800x800 -threads 0 -f mp4 untitled.mp4
import java.text.DecimalFormat;

float[] tweenDest = {0,0,0,0,0,0,0,0,0,0,0,0};
float[] tweenSrce = {0,0,0,0,0,0,0,0,0,0,0,0};
float tweenSteps;
float tweenIdx;
boolean isTweening = false;
int lastTweenSnapshot = -1;
int tweenFrameCtr = 0; // this does not reset, so you can save multiple sequences from one session
DecimalFormat df = new DecimalFormat("#0000");

void saveTweenSnapshot()
{
  System.arraycopy( setupMounts[setupMode], 0, tweenDest, 0, setupMounts[setupMode].length );
  tweenDest[10] = penRig.len;
  tweenDest[11] = penRig.angle;
  lastTweenSnapshot = setupMode;
  println("\n" + getSetupString());
  println("Snapshot saved, now position pen/arms to the starting point and hit S");
}

void beginTweening() 
{
  if (lastTweenSnapshot != setupMode) {
    println("Take a snapshot of the final state by using T, then configure connectors for the beginning state");
    return;
  }
  System.arraycopy( setupMounts[setupMode], 0, tweenSrce, 0, setupMounts[setupMode].length );
  tweenSrce[10] = penRig.len;
  tweenSrce[11] = penRig.angle;

  float maxTravelLength = 0;
  for (MountPoint mp : activeMountPoints) {
    if (mp.setupIdx != -1) {
      maxTravelLength = max(maxTravelLength, mp.getDistance(tweenDest[mp.setupIdx],tweenSrce[mp.setupIdx]));
    }
  }
  maxTravelLength = max(maxTravelLength, abs(tweenSrce[10]-tweenDest[10]) * abs(kPenLabelIncr));
  println("Max travel length: " + maxTravelLength/inchesToPoints);
  tweenSteps = int(maxTravelLength); // One frame for each point of travel.
  println("Movie will be " + tweenSteps + " frames and will take " + tweenSteps/30.0 + " at 30 fps");
  tweenIdx = 0;
  isTweening = true;
  clearPaper();
  completeDrawing();
}

void nextTween() 
{
  if (!isTweening)
    return;

  // save snapshot
  tweenFrameCtr += 1;
  tweenIdx += 1;

  saveSnapshotAs("frame_" + df.format(tweenFrameCtr) + ".png");
  println("Frame: " + df.format(tweenIdx) + "/" + df.format(tweenSteps));

  if (tweenIdx >= tweenSteps) {
    isTweening = false;
    println("Animation complete");
    return;
  }
  
  for (MountPoint mp : activeMountPoints) {
    if (mp.setupIdx != -1) {
      float src = tweenSrce[mp.setupIdx];
      float dst = tweenDest[mp.setupIdx];
      mp.itsMountLength = src + (dst-src)*tweenIdx/(float)tweenSteps;
    }
  }
  float src = tweenSrce[10];
  float dst = tweenDest[10];
  penRig.len = src + (dst-src)*tweenIdx/(float)tweenSteps;

  src = tweenSrce[11];
  dst = tweenDest[11];
  penRig.angle = src + (dst-src)*tweenIdx/(float)tweenSteps;

  clearPaper();
  completeDrawing();
}
