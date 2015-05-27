boolean startupAlert = true;
boolean drawHelp = false;
long    helpStartMS = millis();
String[] helpLines = {
    "0-9 to set speed.",
    "a-d to change setups.",
    "x to erase the paper.",
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

    float hx = width-250;
    float hy = height-22*helpLines.length;
    
    fill(255,alpha*alpha*192);
    rect(hx-1, hy-18, width-hx, height-(hy-18));

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
    text("Press ? for Help", width-150, height-25);
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
