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
    console.log("Got Setup: " + $.cookie('cdms_setups'));
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
  console.log(setupJson);
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

function setupButtons() {
  $('.bcmd').on('click', function(evt) {
    var id = getButtonID(evt);
    var tokens = id.split(':');
    var cmd = tokens[1];
    var subCmd = tokens.length >= 2? tokens[2] : '';
    var processingInstance = Processing.getInstanceById('CDMS');

    processingInstance.issueCmd(cmd, subCmd);
  });
  $('.credits-btn').on('click', function(evt) {
    console.log("Togglging");
    $('#CDMS-credits').toggle();
  });
}
