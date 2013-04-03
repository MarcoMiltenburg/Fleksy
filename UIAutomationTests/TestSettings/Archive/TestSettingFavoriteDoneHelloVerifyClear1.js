/*
 
 iFlesky Test - Test_iFlesky.InitialCrash
 Filename: TestSettingFavoriteDoneHelloVerifyClear1.js
  
 1. Launch App
 2. Tap Menu Ball
 3. Tap Settings.
 4. Tap Favorites
 5. Enter phone number: 1234567890
 6. Tap Done
 7. Tap keyboard: Hello
 8. Tap Menu Ball
 8. Verify that Button with 1234567890 exists and get the name() text
 9. Compare
 10. Clear everything
 11. Test: Compare testValue
 
 */

var MAX_COUNT = 1
var testName1 = "Test_iFlesky.InitialCrash.";

var target = UIATarget.localTarget();

UIALogger.logStart("Test start");

var count = 0;

while (count++ != MAX_COUNT) {
    
    var testName = testName1 + count;
    
    target.frontMostApp().windows()[1].buttons()["Action"].tap();
    target.frontMostApp().windows()[1].popover().actionSheet().buttons()["Settings"].tap();
    target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Favorites"].textFields()[0].tap();
    target.frontMostApp().keyboard().typeString("5106811234");
    target.frontMostApp().navigationBar().rightButton().tap();
    target.frontMostApp().windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.62, y:0.82}});
    target.frontMostApp().windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.26, y:0.70}});
    target.frontMostApp().windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.92, y:0.82}});
    target.frontMostApp().windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.93, y:0.82}});
    target.frontMostApp().windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.86, y:0.71}});
    
    target.frontMostApp().windows()[1].buttons()["Action"].tap();
    
    target.logElementTree();
    
    //UIAButton: name:Send to 5106811234 rect:{{478, 161}, {272, 43}}
    
    var testValue = target.frontMostApp().windows()[1].popover().actionSheet().buttons()["Send to 5106811234"].name()
    var compareValue = "Send to 5106811234";
	
    UIALogger.logMessage( testValue );
    
    target.frontMostApp().windows()[1].popover().actionSheet().buttons()["Settings"].tap();
    target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()["Favorites"].textFields()[0].tap();
    
    target.delay(1);
    
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().keyboard().keys()["Delete"].tap();
    target.frontMostApp().navigationBar().rightButton().tap();
    target.frontMostApp().windows()[1].buttons()["Action"].tap();
    target.frontMostApp().windows()[1].popover().actionSheet().buttons()["Copy & Clear"].tap();
    
    target.delay(1);
	
    if (testValue == compareValue) {
        UIALogger.logPass( testName );
    }
    else {
        UIALogger.logFail( testName );  
    }
	
    //target.setDeviceOrientation(UIA_DEVICE_ORIENTATION_PORTRAIT);
	
	
} //while (count++ != MAX_COUNT)