// Javascript support goes here...

var useDebugging = false;

function mydebug(msg) {
  if (useDebugging) {
    console.log("Debug: " + msg);
  }
}

function jsLoadSetups(csetup) {
  // Load default setups from cookies
  if ($.cookie('cdms_setups')) {
    mydebug("Got Setup: " + $.cookie('cdms_setups'));
    var cs = $.parseJSON($.cookie('cdms_setups'));
    csetup.setupMode = cs.setupMode;
    csetup.setupTeeth = cs.setupTeeth;
    csetup.setupMounts = cs.setupMounts;
    csetup.setupPens = cs.setupPens;
    csetup.setupInversions = cs.setupInversions;
    csetup.penColorIdx = cs.penColorIdx;
    csetup.penWidthIdx = cs.penWidthIdx;

  }
}

function jsSaveSetups(csetup) {
  // Save the setups here to the cdms_setups cookie
  csl = {'setupMode':csetup.setupMode,
         'setupTeeth':csetup.setupTeeth, 
         'setupMounts':csetup.setupMounts, 
         'setupPens':csetup.setupPens, 
         'setupInversions':csetup.setupInversions,
         'penColorIdx':csetup.penColorIdx,
         'penWidthIdx':csetup.penWidthIdx,
       };
  var setupJson = JSON.stringify(csl);
  mydebug(setupJson);
  $.cookie('cdms_setups', setupJson, {expires:7});
}

function getButtonID(e) {
  var elem = $(e.currentTarget);  // switched from target to currentTarget to get the target of the click handler
  var ctr = 0;
  while (elem.attr('id') == undefined && ctr < 5) {
    elem = elem.parent();
    ctr += 1;
  }
  return elem.attr('id');
}

function buttonFeedback()
{
  var processingInstance = Processing.getInstanceById('CDMS');

  var setupMode = processingInstance.getSetupMode();
  var passesPerFrame = processingInstance.getPassesPerFrame();
  var drawDirection = processingInstance.getDrawDirection();
  var isMoving = processingInstance.getIsMoving();

  var playMode = 'pause';
  if (isMoving && passesPerFrame != 0) {
    if (drawDirection == -1) {
      if (passesPerFrame < 10)
        playMode = 'rr';
      else
        playMode = 'rrr';
    } else {
      if (passesPerFrame < 10)
        playMode = 'play';
      else if (passesPerFrame < 720)
        playMode = 'ff';
      else
        playMode = 'fff';
    }
  }
  $('.bcmd').removeClass('active');
  $('#lcmd\\:setup\\:' + setupMode).addClass('active');
  $('#lcmd\\:'+playMode).addClass('active');
  mydebug("feedback " + setupMode + " " + playMode);
}

function setupButtons() {
  $('.bcmd').on('click', function(evt) {
    var id = getButtonID(evt);
    var tokens = id.split(':');
    var cmd = tokens[1];
    var subCmd = tokens.length >= 2? tokens[2] : '';
    var processingInstance = Processing.getInstanceById('CDMS');

    processingInstance.issueCmd(cmd, subCmd);
    buttonFeedback();
  });
  $('.credits-btn').on('click', function(evt) {
    $('#CDMS-credits').toggle();
  });
  buttonFeedback();
}

function makeSnapshot(pgraphics, rotation) 
{
   var pi = Processing.getInstanceById('Snapper');
   pi.snapPicture(pgraphics, rotation);
}
