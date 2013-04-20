/*
 
 iFlesky Test - Test_iFleksyLaunchMemTest.js
  
 1. Launch App
 2. Just makes sure that Cool! Alert is handled by test
 
 */

#import "../../tuneup/tuneup.js"

function onFleksyAlert(alert) {
    UIALogger.logMessage("alert Shown: " + alert);
	target.logElementTree();
	//UIALogger.logMessage("alert after log");
    
    if (alert.buttons()["DELETE"].name() != null) {
        UIALogger.logMessage("DELETE alert");
        alert.buttons()["DELETE"].tap();
        UIALogger.logMessage("alert DELETE handled");
        return true;
    }
    else if (alert.buttons()["Cool!"].name() != null) {
        //UIALogger.logMessage("Cool! alert " + alert.buttons()["Cool!"] + ", " + alert.cancelButton());
        alert.buttons()["Cool!"].tap();
        //alert.cancelButton().tap();
    	return true;
    }
    UIALogger.logMessage("did not handle_");
    return false;
}

function swipeDown() {
    target.delay(1);
    UIALogger.logMessage("Swipe Down");
    target.flickInsideWithOptions({startOffset:{x:0.62, y:0.3}, endOffset:{x:0.62, y:0.5}});
}

function swipeUp() {
    target.delay(1);
    UIALogger.logMessage("Swipe UP");
    target.flickInsideWithOptions({startOffset:{x:0.62, y:0.5}, endOffset:{x:0.62, y:0.3}});    
}

function swipeLeft() {
    target.delay(1);
    UIALogger.logMessage("Swipe Left");
    target.flickInsideWithOptions({startOffset:{x:0.8, y:0.5}, endOffset:{x:0.6, y:0.5}});
}

function swipeRight() {
    target.delay(1);
    UIALogger.logMessage("Swipe Right");
    target.flickInsideWithOptions({startOffset:{x:0.62, y:0.5}, endOffset:{x:0.82, y:0.5}});  
}


var MAX_COUNT = 1
var testName1 = "Test_iFleksyLaunchMemTest.js";

UIATarget.onAlert = function(alert) {
	UIALogger.logMessage("empty onAlert handler, returning false");
    return false;
}

test(testName1, function(target,app) {
     
     
     //UIATarget.onAlert
     
     // Loading . . requires a delay for initial blank TextView
     //target.delay(20);
     
     //UIALogger.logMessage("Pushing an initial 60 second timeout for Loading");
     
     target.pushTimeout(0);
     
     
	var keyboardWindow = null;     
     
     //UIALogger.logMessage("past 60 push");
     // This initializes the app to a known state
     
     while (true) {
     
     	for (var i = 0; i < app.windows().length; i++) {
     		var temp = app.windows()[i].elements()["Activate keyboard with a single tap before typing"];
     		if (temp && temp.isValid()) {
     			keyboardWindow = app.windows()[i];
     			break;
     		}
     		
	     
     	}
     	
   
     	
     	if (keyboardWindow) {
     		break;
     	}
     	
     	var delay = 1;
     	UIALogger.logMessage("Did not find keyboardWindow. waiting " + delay);
     	target.delay(delay);
     	
     	
     	 // UIALogger.logMessage("0000");
//      		if (hasAlert(app)) {
//      		UIALogger.logMessage("1111");
//      		onFleksyAlert(app.alert());
//      		UIALogger.logMessage("2222");
//      	
//      	}
     	
     }
     
     UIATarget.onAlert = onFleksyAlert;
     
     UIALogger.logMessage("keyboardWindow: " + keyboardWindow);
     //keyboardWindow.logElementTree();
     
     var actionButton = null;
     
     while (!actionButton || !actionButton.isValid()) {
     	UIALogger.logMessage("waiting 1 second for actionButton: " + actionButton + ", kbw: " + keyboardWindow);
     	//keyboardWindow.logElementTree();
     	target.delay(1);
     	actionButton = keyboardWindow.buttons()["Action"];
     	
     	//target.logElementTree();
	
     }
     
     UIALogger.logMessage("NORMAL FAST EXIT FOR TESTING");
     return true;
});
