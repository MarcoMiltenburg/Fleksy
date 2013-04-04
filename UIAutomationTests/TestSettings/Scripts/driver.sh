#!/bin/sh

#USAGE: run-test-script <app bundle> <test script> <output directory> [optional args]
#  If <app bundle> is the name of the app without extension, the newest bundle is located autmatically
#    -d, --device DEVICE              Device UDID to run test against,
#                                     or 'dynamic' to find the UDID at runtime
#    -e, --environment ENV            Pass variables in the form of name=value
#    -t, --timeout DURATION           Maximum time in seconds with no output
#    -r, --run TEST                   Only run tests named alike. It's possible to use RegExps.
#    -v, --verbose                    Produce more output
#    -q, --quiet                      Don't print test results to console
#    -c, --color                      Colorize the console output
#    -p, --preprocess                 Use own preprocessor to substitude imports
#    -x, --xunit                      Create Xunit formatted test result file in the output directory
#    -l, --language=en                Use language to simulator
#    -h, --help                       Show this message

#Library/Developer/Xcode/DerivedData/iFleksy-cnieacgsclhowuapljisvitxicyg/Build/Products/Debug-iphonesimulator

FEATURE=Settings
FLEKSY_PATH=~/Xcode/Fleksy
IFLEKSY_DIR=$FLEKSY_PATH/iFleksy

FL_AUTOMATIONTEST_PATH=$IFLEKSY_DIR/UIAutomationTests
FL_APPBUNDLE_PATH=~/Library/Developer/Xcode/DerivedData/iFleksy-cnieacgsclhowuapljisvitxicyg/Build/Products/Debug-iphonesimulator
FL_APPNAME=Fleksy.app
FL_APPBUNDLE=$FL_APPBUNDLE_PATH/$FL_APPNAME
FL_TEST_DIR=Test$FEATURE/Tests
FL_AUTOMATIONTEST_RESULTS_PATH=iFleksy_Testing/UIAutomation/Results
FL_TEST_RESULTS_DIR=Test$FEATURE

TESTRUNNER_PATH=$FL_AUTOMATIONTEST_PATH/tuneup/test_runner
TESTER=$TESTRUNNER_PATH/run

FL_TEST=Test_iFleksySettingFavoriteDoneHelloVerifyClear.js

echo $FL_APPNAME : $FL_TEST
echo
echo BEGIN Test Driver 800 times >> $0
COUNT=0
while [ $COUNT != 800 ] 
do
    echo TEST:  $COUNT 
    $TESTER $FL_APPBUNDLE $FL_AUTOMATIONTEST_PATH/$FL_TEST_DIR/$FL_TEST ../Results/$FL_TEST_RESULTS_DIR --verbose --timeout 70
    sleep 1
    let COUNT=$COUNT+1
done

echo TEST Driver Cycle Completed $COUNT Runs
