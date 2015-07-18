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
	"x" : "screenSizeX/2",
	"y" : "screenOriginY",
	"width" : "screenSizeX/2",
	"height" : "screenSizeY"
});

var throwLeftFullScreen = slate.operation("throw", {
	"x" : "screenOriginX",
	"y" : "screenOriginY",
	"width" : "screenSizeX",
	"height" : "screenSizeY",
	"screen" : 0
});

var throwRightFullScreen = slate.operation("throw", {
	"x" : "screenOriginX",
	"y" : "screenOriginY",
	"width" : "screenSizeX",
	"height" : "screenSizeY",
	"screen" : 1
});

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

var grid = slate.operation("grid", {
	"grids" : {
		"1920x1080" : {
			"width" : 16,
			"height" : 9
		}
	}
});
slate.bind("g:alt", grid);

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
slate.bind("left:alt,cmd", throwLeftFullScreen);
slate.bind("right:alt,cmd", throwRightFullScreen);

//Fullscreen toggle
slate.bind("f:alt,cmd", fullScreenToggle);
