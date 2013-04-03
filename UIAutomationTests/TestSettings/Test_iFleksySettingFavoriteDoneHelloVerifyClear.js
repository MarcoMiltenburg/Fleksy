/*
 
 iFlesky Test - Test_iFleksySettingFavoriteDoneHelloVerifyClear
  
 1. Launch App
 2. Tap Menu Ball
 3. Tap Settings.
 4. Tap Favorites
 5. Enter phone number: 0123456789
 6. Tap Done
 7. Tap keyboard: Hello
 8. Tap Menu Ball
 8. Verify that Button with 0123456789 exists and get the name() text
 9. Compare
 10. Clear everything
 11. Test: Compare testValue
 
 */

#import "../tuneup/tuneup.js"

var MAX_COUNT = 1
var testName1 = "Test_iFleksySettingFavoriteDoneHelloVerifyClear.";

test(testName1, function(target,app) {
     
     UIALogger.logStart("Test start");
     
     var count = 0;
     
     while (count++ != MAX_COUNT) {
     
         var testName = testName1 + count;
         
         app.windows()[1].buttons()["Action"].tap();
         app.windows()[1].popover().actionSheet().buttons()["Settings"].tap();
         app.mainWindow().tableViews()["Empty list"].cells()["Favorites"].textFields()[0].tap();
         app.keyboard().typeString("0123456789");
         app.navigationBar().rightButton().tap();
         
         // Slowly Tap Hello on Keyboard
     
         app.windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.62, y:0.82}});
         app.windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.26, y:0.70}});
         app.windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.92, y:0.82}});
         app.windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.93, y:0.82}});
         app.windows()[1].elements()["Activate keyboard with a single tap before typing"].tapWithOptions({tapOffset:{x:0.86, y:0.71}});
         
         app.windows()[1].buttons()["Action"].tap();
         
         target.logElementTree();
         
         //UIAButton: name:Send to 0123456789 rect:{{478, 161}, {272, 43}}
         
         var testValue = app.windows()[1].popover().actionSheet().buttons()["Send to 0123456789"].name()
         var compareValue = "Send to 0123456789";
         
         UIALogger.logMessage( testValue );
         
         app.windows()[1].popover().actionSheet().buttons()["Settings"].tap();
         app.mainWindow().tableViews()["Empty list"].cells()["Favorites"].textFields()[0].tap();
         
         target.delay(1);
         
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.keyboard().keys()["Delete"].tap();
         app.navigationBar().rightButton().tap();
         app.windows()[1].buttons()["Action"].tap();
     
         target.delay(1);
     
         app.windows()[1].popover().actionSheet().buttons()["Copy & Clear"].tap();
         
         //         if (testValue == compareValue) {
         //         UIALogger.logPass( testName );
         //         }
         //         else {
         //         UIALogger.logFail( testName );
         //         }
         
         assertEquals(compareValue, testValue, "Menu > Sent to button must match expected value from Settings > Favorite");
         
         //target.setDeviceOrientation(UIA_DEVICE_ORIENTATION_PORTRAIT);
     
     
     } //while (count++ != MAX_COUNT)
     
});