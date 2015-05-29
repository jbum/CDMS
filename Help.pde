boolean startupAlert = true;
boolean drawHelp = false;
long    helpStartMS = millis();
String[] helpLines = {
    "0-9     set drawing speed",
    "a-g     change setups",
    "arrows  change gears and mount points",
    "x       erase the paper",
    "[ ]     change pen color",
    "< >     change pen width",
    "/       invert connecting rod",
    "s       save the image",
    "~       draw entire cycle",
    "T       save tween endpoint",
    "S       animate to endpoint (slow!)",
    "H       toggle Hi-res",
};

void helpDraw() 
{
  if (drawHelp) {
    long elapsed = millis() - helpStartMS;
    float alpha = constrain(map(elapsed, 10*1000, 13*1000, 1, 0),0,1);
    if (alpha <= 0.0001) {
      drawHelp = false;
    }
    noStroke();

    float hx = width-450;
    float hy = 30;
    
    fill(255,alpha*alpha*192);
    rect(hx-1, 0, width-hx, hy + 22*helpLines.length);

    fill(100, alpha*alpha*255);

    textFont(hFont);
    textAlign(LEFT);
    for (int i = 0; i < helpLines.length; ++i) {
      text(helpLines[i], hx, hy+22*i);
    }
  }
  else if (startupAlert) {
    long elapsed = millis() - helpStartMS;
    float alpha = constrain(map(elapsed, 5*1000, 8*1000, 1, 0),0,1);
    if (alpha <= 0.0001) {
      startupAlert = false;
    }
    textFont(hFont);
    textAlign(LEFT);
    fill(200, alpha*alpha*255);
    text("Press ? for Help", width-200, 30);
  }
}

void toggleHelp() 
{
  if (drawHelp) {
    drawHelp = false;
  } else {
    drawHelp = true;
    startupAlert = false;
    helpStartMS = millis();
  }
}
