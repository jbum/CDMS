boolean startupAlert = true;
boolean drawHelp = false;
long    helpStartMS = millis();


void helpDraw() 
{
  if (drawHelp) {
    long elapsed = millis() - helpStartMS;
    float alpha = constrain(map(elapsed, 10*1000, 13*1000, 1, 0),0,1);
    if (alpha <= 0.0001) {
      drawHelp = false;
    }
    fill(200, alpha*alpha*255);
    float hx = width-200;
    float hy = height-25;
    
    text("Press 0-9 to set speed.", hx, hy);
  }
  else if (startupAlert) {
    long elapsed = millis() - helpStartMS;
    float alpha = constrain(map(elapsed, 5*1000, 8*1000, 1, 0),0,1);
    if (alpha <= 0.0001) {
      startupAlert = false;
    }
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
