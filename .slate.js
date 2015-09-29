var modes = ['tiling', 'single', 'free'];
var mode = modes.indexOf('single');

slate.configAll({
	"defaultToCurrentScreen" : true,
	"secondsBetweenRepeat" : 0.05,
	"secondsBeforeRepeat" : 0.3,
	"windowHintsIgnoreHiddenWindows" : false,
	"windowHintsSpread" : true,
	"windowHintsShowIcons" : true,
	"windowHintsFontColor" : "255;0;0;1.0",
	"windowHintsBackgroundColor" : "50;53;58;0.5",
	"windowHintsSpreadSearchWidth" : 100,
	"windowHintsSpreadSearchHeight" : 100,
	"windowHintsSpreadPadding" : 5,
});

var focusChrome = slate.operation("focus", {
	"app" : "Google Chrome"
});

var focusAbove = slate.operation("focus", {
	"direction" : "above"
});

var focusBelow = slate.operation("focus", {
	"direction" : "below"
});

var focusLeft = slate.operation("focus", {
	"direction" : "left"
});

var focusRight = slate.operation("focus", {
	"direction" : "right"
});

var makeHigher = slate.operation("resize", {
	"width" : "+0",
	"height" : "+10%"
});

var makeShorter = slate.operation("resize", {
	"width" : "+0",
	"height" : "-10%"
});

var makeWider = slate.operation("resize", {
	"width" : "+10%",
	"height" : "+0"
});

var makeThiner = slate.operation("resize", {
	"width" : "-10%",
	"height" : "+0"
});

var moveLeft = slate.operation("nudge", {
	"x" : "-10%",
	"y" : "+0"
});

var moveRight = slate.operation("nudge", {
	"x" : "+10%",
	"y" : "+0"
});

var moveUp = slate.operation("nudge", {
	"x" : "+0",
	"y" : "-10%"
});

var moveDown = slate.operation("nudge", {
	"x" : "+0",
	"y" : "+10%"
});

var topFullWidth = slate.operation("move", {
	"x" : "screenOriginX",
	"y" : "screenOriginY",
	"width" : "screenSizeX",
	"height" : "screenSizeY/2"
});

var bottomFullWidth = slate.operation("move", {
	"x" : "screenOriginX",
	"y" : "screenSizeY/2",
	"width" : "screenSizeX",
	"height" : "screenSizeY/2"
});

var leftFullHeight = slate.operation("move", {
	"x" : "screenOriginX",
	"y" : "screenOriginY",
	"width" : "screenSizeX/2",
	"height" : "screenSizeY"
});

var rightFullHeight = slate.operation("move", {
	"x" : "screenOriginX+(screenSizeX/2)",
	"y" : "screenOriginY",
	"width" : "screenSizeX/2",
	"height" : "screenSizeY"
});

var throwFullScreen = function(direction, win) {
  var screensCount = slate.screenCount();
  var currentScreen = win.screen().id();
  var newScreen = (currentScreen+direction) % screensCount;
  newScreen = (newScreen < 0) ? (screensCount-1) : newScreen;
  win.doOperation("throw", {
    "x" : "screenOriginX",
    "y" : "screenOriginY",
    "width" : "screenSizeX",
    "height" : "screenSizeY",
    "screen" : newScreen
  });
};

var throwToScreen = function(direction, win) {
  var screensCount = slate.screenCount();
  var currentScreen = win.screen().id();
  var newScreen = (currentScreen+direction) % screensCount;
  newScreen = (newScreen < 0) ? (screensCount-1) : newScreen;

  slate.log("Current screen: " + win.screen().id());
  slate.log("New screen: " + newScreen);
  var winRect = win.rect();
  var scrObj = slate.screenForRef(newScreen);
  var scrRect = scrObj.visibleRect();
  slate.log(scrRect.width + "x" + scrRect.height);
  slate.log(winRect.width + "x" + winRect.height);
  win.doOperation("throw", {
    "x" : parseInt((scrRect.width-winRect.width) / 2),
    "y" : parseInt((scrRect.height-winRect.height) / 2),
    "width" : winRect.width,
    "height" : winRect.height,
    "screen" : scrObj
  });
  slate.log('Window thrown');
};

var fullScreen = slate.operation("move", {
	"x" : "screenOriginX",
	"y" : "screenOriginY",
	"width" : "screenSizeX",
	"height" : "screenSizeY"
});

var halfScreenCenter = slate.operation("move", {
	"x" : "screenSizeX*0.05",
	"y" : "screenSizeY*0.05",
	"width" : "screenSizeX*0.9",
	"height" : "screenSizeY*0.9"
});

var fullScreenToggle = slate.operation("chain", {
	"operations" : [fullScreen, halfScreenCenter]
});

var hint = slate.operation("hint");
slate.bind("f:alt", hint);

var relaunch = slate.operation("relaunch");
slate.bind("r:alt", relaunch);

var shouldTileWindow = function (win, scrId, excludes) {
  excludes = excludes||[];
  return (win.screen().id() == scrId && !win.isMinimizedOrHidden() && win.isResizable() && win.isMovable() && win.title() && excludes.indexOf(win.app().name()) == -1);
};

var countWindowsOnScreen = function(scrId) {
  var totalWindows = 0;
  slate.eachApp(function(app) {
    app.eachWindow(function(win) {
      if (shouldTileWindow(win, scrId)) {
        totalWindows++;
      }
    });
  });
  return totalWindows;
};

var tileAll = function() {
  var scr, rect, topLeftX, topLeftY, scrWidth, scrHeight;
  try {
    scr = slate.screen();
    rect = scr.visibleRect();
    topLeftX = rect.x;
    topLeftY = rect.y;
    scrWidth = rect.width;
    scrHeight = rect.height;
  } catch (e) {
    return;
  }

  var totalWindows = countWindowsOnScreen(scr.id());
  var winCountLeft = parseInt(totalWindows / 2);
  var winCountRight = (totalWindows % 2 === 0) ? winCountLeft : winCountLeft+1;
  var posWindowsCounts = [0,0];
  var pos = 'left';

  slate.eachApp(function(app) {
    app.eachWindow(function(win) {
      if (totalWindows == 1) {
        win.doOperation(halfScreenCenter);
      } else if (totalWindows > 1) {
        if (!shouldTileWindow(win, scr.id())) return;

        var winCounts, sideWinCounts;
        switch (pos) {
          case 'left':
            winCounts = posWindowsCounts[0];
            posWindowsCounts[0]++;
            sideWinCounts = winCountLeft;
            break;
          case 'right':
            winCounts = posWindowsCounts[1];
            posWindowsCounts[1]++;
            sideWinCounts = winCountRight;
            break;
        }

        var x = (pos == 'left') ? topLeftX : topLeftX+scrWidth/2;
        var y = topLeftY + (scrHeight / sideWinCounts * winCounts);
        var width = scrWidth/2;
        var height = scrHeight / sideWinCounts;

        win.doOperation("move", {
          "x" : x,
          "y" : y,
          "width" : width,
          "height" : height,
          "screen" : scr
        });

        pos = (pos == 'left') ? 'right' : 'left';
        if (pos == 'left' && posWindowsCounts[0] == winCountLeft) pos = 'right';
      }
    });
  });
};

var hideAll = function() {
  if (!isMode('single')) return;

  var scrId = slate.screen().id();
  slate.eachApp(function(app) {
    app.eachWindow(function(win) {
      if (win.screen().id() == scrId) {
        slate.log("Hiding " + app.name() + " from screen " + win.screen().id() + " while aiming at screen " + scrId);
        slate.operation('hide', {
          "app" : [app.name()]
        }).run();
      }
    });
  });
};

var cycleThroughModes = function() {
  mode = (mode+1) % modes.length;
  slate.shell("/usr/bin/osascript -e 'display notification \"Tiling mode changed to " + modes[mode] + "\" with title \"Slate\"'", false);
};

var isMode = function(str) {
  return mode == modes.indexOf(str);
};

var bringUp = function(appName, autoTile) {
  slate.log("Shortcut: " + appName);
  autoTile = autoTile||false;
  slate.operation('show', {
    "app" : [appName]
  }).run();

  if (autoTile) {
    tileAll();
  } else {
    slate.eachApp(function(app){
      slate.eachWindow(function(win){
        if(app.name() == appName) {
          win.doOperation(halfScreenCenter);
        }
      });
    });
  }

  slate.operation('focus', {
    "app" : appName
  }).run();
};

slate.on('windowOpened', function(e, win) {
  if (isMode('free')) return;
  //TODO: when new window is spawned, move it to the screen less windows (or calculate the area of the new window if it were to be placed on each screen and place it where it will have the largest area)
  if (win.title().match(/^chrome-devtools/)) {
    win.doOperation(throwToScreen(1, win));
  }
  if (win.isResizable() && win.isMain() && isMode('tiling')) {
    tileAll();
  }
});

slate.on('windowClosed', function(e, app) {
  if (isMode('free')) return;
  //tileAll();
});

slate.on('appClosed', function(e, app) {
  if (isMode('free')) return;

  if (isMode('tiling')) {
    tileAll();
  }
});

var grid = slate.operation("grid", {
	"grids" : {
		"1920x1080" : {
			"width" : 16,
			"height" : 9
		},
		"1440x900" : {
			"width" : 16,
			"height" : 10
		}
	}
});
slate.bind("g:alt", grid);
slate.bind("t:alt", tileAll);

var undo = slate.operation("undo");
slate.bind("u:alt", undo);

//Focus bindings
//slate.bind("2:ctrl", focusChrome);
slate.bind("up:ctrl", focusAbove);
slate.bind("down:ctrl", focusBelow);
slate.bind("left:ctrl", focusLeft);
slate.bind("right:ctrl", focusRight);

//Push bindings
slate.bind("up:ctrl,cmd", topFullWidth);
slate.bind("down:ctrl,cmd", bottomFullWidth);
slate.bind("left:ctrl,cmd", leftFullHeight);
slate.bind("right:ctrl,cmd", rightFullHeight);

//Resize bindings
/*slate.bind("j:ctrl,alt", makeHigher);
slate.bind("k:ctrl,alt", makeShorter);
slate.bind("h:ctrl,alt", makeWider);
slate.bind("l:ctrl,alt", makeThiner);*/

//Move bindings
slate.bind("up:ctrl,alt", moveUp);
slate.bind("down:ctrl,alt", moveDown);
slate.bind("left:ctrl,alt", moveLeft);
slate.bind("right:ctrl,alt", moveRight);

//Throw bindings
slate.bind("left:alt,cmd", function(win) {
  throwToScreen(-1, win);
});
slate.bind("right:alt,cmd", function(win) {
  throwToScreen(1, win);
});

slate.bind("m:alt,cmd", function(win) {
  cycleThroughModes();
});

//Fullscreen toggle
slate.bind("f:alt,cmd", fullScreenToggle);

//Focus single app
slate.bind("h:j,cmd", function(win) {
  hideAll();
  bringUp("HipChat");
});
slate.bind("i:j,cmd", function(win) {
  hideAll();
  bringUp("iTerm");
});
slate.bind("g:j,cmd", function(win) {
  hideAll();
  bringUp("Google Chrome");
});
slate.bind("m:j,cmd", function(win) {
  hideAll();
  bringUp("Mail");
});
slate.bind("f:j,cmd", function(win) {
  hideAll();
  bringUp("Finder");
});
slate.bind("s:j,cmd", function(win) {
  hideAll();
  bringUp("Spotify");
});
slate.bind("t:j,cmd", function(win) {
  hideAll();
  bringUp("TextEdit");
});
slate.bind("l:j,cmd", function(win) {
  hideAll();
  bringUp("LimeChat");
});

//Focus on multiple apps
slate.bind("h:j,alt:toggle", function(win) {
  bringUp("HipChat", true);
});
slate.bind("i:j,alt:toggle", function(win) {
  bringUp("iTerm", true);
});
slate.bind("g:j,alt:toggle", function(win) {
  bringUp("Google Chrome", true);
});
slate.bind("m:j,alt:toggle", function(win) {
  bringUp("Mail", true);
});
slate.bind("f:j,alt:toggle", function(win) {
  bringUp("Finder", true);
});
slate.bind("s:j,alt:toggle", function(win) {
  bringUp("Spotify", true);
});
slate.bind("t:j,alt:toggle", function(win) {
  bringUp("TextEdit", true);
});
slate.bind("l:j,alt:toggle", function(win) {
  bringUp("LimeChat", true);
});
