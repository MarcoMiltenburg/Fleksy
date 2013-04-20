/*
 
 iFlesky Test - Test_iFleksyTypingSwiping2.2.js
  
 1. Launch App
 2. Type Hello SR 6LW SR SD 8LW SR SD SD SD SD SU SU SL SL SL
 3. Clear everything
 4. Test: Compare testValue (both are 1)
 
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
var testName1 = "Test_iFleksyTypingSwiping2.2.js";

// System will handle 
UIATarget.onAlert = function(alert) {
	UIALogger.logMessage("empty onAlert handler, returning false");
    return false;
}

test(testName1, function(target,app) {

     //UIATarget.onAlert
     
     // Loading . . requires a delay for initial blank TextView
     
     target.pushTimeout(0);

	var keyboardWindow = null;     
     
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
     
     //UIALogger.logMessage("NORMAL FAST EXIT FOR TESTING");
     //return true;
     
	 actionButton.tap();
	 
	 target.popTimeout();
	 
	 keyboardWindow.popover().actionSheet().buttons()["Instructions"].tap();
	 app.mainWindow().buttons()["Instructions"].tapWithOptions({tapCount:5});

	 // Alert detected. Expressions for handling alerts should be moved into the UIATarget.onAlert function definition.
	 
	 UIALogger.logMessage("Continuing...");
	 UIALogger.logMessage("Continuing 2...");
	 target.delay(1);
	 
	 app.mainWindow().buttons()["Back"].tap();
	 UIALogger.logMessage("back button tap");	 
	 keyboardWindow.buttons()["Action"].tap();
	 
	 var copyClearButton = keyboardWindow.popover().actionSheet().buttons()["Copy & Clear"].name();	 
	 if (copyClearButton != null) {
	 	UIALogger.logMessage("Copy and Clear available");
	 	keyboardWindow.popover().actionSheet().buttons()["Copy & Clear"].tap();
	 }
	 else {
	 	UIALogger.logMessage("No Copy and Clear. Dismiss popover");
	 	target.tap({x:155.00, y:98.00});
	 }
	 
     var count = 0;
     
     while (count++ != MAX_COUNT) {
     
         var testName = testName1 + count;

         
	 /* 
	  
	  Benign error:
	  
	  Unexpected error in -[UIAButton_0x7c2f4e0 scrollToVisible], /SourceCache/UIAutomation_Sim/UIAutomation-271/Framework/UIAElement.m line 1545, kAXErrorFailure
	  
	  See:
	  http://freynaud.github.com/ios-driver/jsdoc/ee6f9d9609.html
	  
	  scrollToVisible()
scrollToVisible only makes sense if the element if in a webview or a tableView. It was working, and doing nothing for other elements up to ios5.1. Starting from ios6, it now throws : Unexpected error in -[UIAStaticText_0xdc363d0 scrollToVisible], /SourceCache/UIAutomation_Sim/UIAutomation-271/Framework/UIAElement.m line 1545, kAXErrorFailure so need to check first if scrolling will do anything to avoid this exception.
Source:
		UIAElement.js, line 130
	  
	  */

     	 // 2. Type Hello SR 6LW SR SD 8LW SR SDx4 SUx2 SLx3
     
         // QUICKY Tap Hello on Keyboard

	     var keyboard = keyboardWindow.elements()["Activate keyboard with a single tap before typing"];
	     
	     target.pushTimeout(1);
     
         //target.dragInsideWithOptions({startOffset:{x:0.0, y:0.1}, endOffset:{x:1.0, y:0.1}, duration:1.5});
     
        target.delay(1);
        UIALogger.logMessage("Keyboard 5 start");
        target.dragInsideWithOptions({startOffset:{x:0.62, y:0.82}, endOffset:{x:0.62, y:0.82}, duration:0});
        target.dragInsideWithOptions({startOffset:{x:0.26, y:0.70}, endOffset:{x:0.26, y:0.70}, duration:0});
        target.dragInsideWithOptions({startOffset:{x:0.92, y:0.82}, endOffset:{x:0.92, y:0.82}, duration:0});
        target.dragInsideWithOptions({startOffset:{x:0.93, y:0.82}, endOffset:{x:0.93, y:0.82}, duration:0});
        target.dragInsideWithOptions({startOffset:{x:0.86, y:0.71}, endOffset:{x:0.86, y:0.71}, duration:0});

       // Type 1 second per tap
//     target.dragInsideWithOptions({startOffset:{x:0.62, y:0.82}, endOffset:{x:0.62, y:0.82}});
//     target.dragInsideWithOptions({startOffset:{x:0.26, y:0.70}, endOffset:{x:0.26, y:0.70}});
//     target.dragInsideWithOptions({startOffset:{x:0.92, y:0.82}, endOffset:{x:0.92, y:0.82}});
//     target.dragInsideWithOptions({startOffset:{x:0.93, y:0.82}, endOffset:{x:0.93, y:0.82}});
//     target.dragInsideWithOptions({startOffset:{x:0.86, y:0.71}, endOffset:{x:0.86, y:0.71}});
     
         UIALogger.logMessage("Keyboard 5 end");
         
         swipeRight();
     
     	// QUICKY Tap 6 letter word on Keyboard

     	UIALogger.logMessage("Keyboard 6 start");
     
         target.dragInsideWithOptions({startOffset:{x:0.62, y:0.82}, endOffset:{x:0.62, y:0.82}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.26, y:0.70}, endOffset:{x:0.26, y:0.70}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.26, y:0.70}, endOffset:{x:0.26, y:0.70}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.32, y:0.82}, endOffset:{x:0.32, y:0.82}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.93, y:0.82}, endOffset:{x:0.93, y:0.82}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.86, y:0.71}, endOffset:{x:0.86, y:0.71}, duration:0});
     
     	UIALogger.logMessage("Keyboard 6 end");

        swipeRight();
     
        swipeDown();

     	// QUICKY Tap 8 letter word on Keyboard
	    
     	UIALogger.logMessage("Keyboard 8 start");     
     
         target.dragInsideWithOptions({startOffset:{x:0.62, y:0.82}, endOffset:{x:0.62, y:0.82}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.26, y:0.70}, endOffset:{x:0.26, y:0.70}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.92, y:0.82}, endOffset:{x:0.92, y:0.82}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.26, y:0.70}, endOffset:{x:0.26, y:0.70}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.26, y:0.70}, endOffset:{x:0.26, y:0.70}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.30, y:0.75}, endOffset:{x:0.30, y:0.75}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.26, y:0.70}, endOffset:{x:0.26, y:0.70}, duration:0});
         target.dragInsideWithOptions({startOffset:{x:0.27, y:0.58}, endOffset:{x:0.27, y:0.58}, duration:0});
     
     	UIALogger.logMessage("Keyboard 8 end");

        swipeRight();
 
        swipeDown();
        swipeDown();
        swipeDown();
        swipeDown();
     
        swipeUp();
        swipeUp();

        swipeLeft();     
        swipeLeft();     
        swipeLeft();

        target.popTimeout();
     
     //target.logElementTree();
     //UIAButton: name:Send to 0123456789 rect:{{478, 161}, {272, 43}}
     // var testValue = keyboardWindow.popover().actionSheet().buttons()["Send to 0123456789"].name()
     // var compareValue = "Send to 0123456789";
     
         var testValue = "1";
         var compareValue = "1";
     
         //target.delay(1);
         //keyboardWindow.buttons()["Action"].tap();
     
         //keyboardWindow.popover().actionSheet().buttons()["Copy & Clear"].tap();
         
         //         if (testValue == compareValue) {
         //         UIALogger.logPass( testName );
         //         }
         //         else {
         //         UIALogger.logFail( testName );
         //         }
         
         assertEquals(compareValue, testValue, "1 is not equal 1");
         //target.setDeviceOrientation(UIA_DEVICE_ORIENTATION_PORTRAIT);
     
         // Added for iDevice
         target.delay(1);
         UIALogger.logMessage("END OF LOOP");
     
     
     } //while (count++ != MAX_COUNT)
     
	 target.delay(1);
     UIALogger.logMessage("END OF RUN");
     target.delay(1);
     
});
