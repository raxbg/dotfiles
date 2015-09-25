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

var tileAll = function() {
  //TODO: when new window is spawned, move it to the screen less windows (or calculate the area of the new window if it were to be placed on each screen and place it where it will have the largest area)
  var scr = slate.screen();

  var rect = scr.visibleRect();
  var topLeftX = rect.x;
  var topLeftY = rect.y;
  var scrWidth = rect.width;
  var scrHeight = rect.height;

  var totalWindows = 0;
  slate.eachApp(function(app) {
    app.eachWindow(function(win) {
      if (win.screen().id() == scr.id() && !win.isMinimizedOrHidden() && win.title()) {
        totalWindows++;
      }
    });
  });
  slate.log('total:: ' + totalWindows);

  if (totalWindows == 1) {
  } else if (totalWindows > 1) {
    var winCountLeft = parseInt(totalWindows / 2);
    var winCountRight = (totalWindows % 2 === 0) ? winCountLeft : winCountLeft+1;
    var posWindowsCounts = [0,0];
    var pos = 'left';

    slate.eachApp(function(app) {
      app.eachWindow(function(win) {
        if (win.screen().id() == scr.id()) {
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
            "screen" : scr.id()
          });

          pos = (pos == 'left') ? 'right' : 'left';
          if (pos == 'left' && posWindowsCounts[0] == winCountLeft) pos = 'right';
        }
      });
    });
  }
};

slate.on('windowOpened', function(e, win) {
  if (win.title().match(/^chrome-devtools/)) {
    win.doOperation(throwFullScreen(1, win));
  }
  tileAll();
});

var grid = slate.operation("grid", {
	"grids" : {
		"1920x1080" : {
			"width" : 16,
			"height" : 9
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
  throwFullScreen(-1, win);
});
slate.bind("right:alt,cmd", function(win) {
  throwFullScreen(1, win);
});

//Fullscreen toggle
slate.bind("f:alt,cmd", fullScreenToggle);
