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


echo command: $0 $1 $2 $3

: ${1?"USAGE: driver.sh <# of runs> [-d | --device <UDID | dynamic>]"}

if [ $1 == "-h" ]; then
    echo "USAGE: driver.sh <# of runs> [-d | --device <UDID | dynamic>]"
    echo "dynamic: auto-search for an iDevice at runtime"
    exit 1
fi

#if [ $2 && $2 == "dynamic" ]; then
#echo "An iDevice will be dynamically found and used"
#fi

#: ${FLEKSY_PATH?"Need to set FLEKSY_PATH in your .profile, i.e. FLEKSY_PATH=~/Xcode/Fleksy"}
if [ -z "$FLEKSY_PATH" ]; then
    echo "Set FLEKSY_PATH in your .profile, i.e. FLEKSY_PATH=~/Xcode/Fleksy then export FLEKSY_PATH"
    exit 1
else
    echo FLEKSY_PATH is ${FLEKSY_PATH}
fi

FEATURE=TypeSRSL
#FLEKSY_PATH=~/Xcode/Fleksy
IFLEKSY_DIR=$FLEKSY_PATH/iFleksy

FL_AUTOMATIONTEST_PATH=$IFLEKSY_DIR/UIAutomationTests
#FL_APPBUNDLE_PATH=~/Library/Developer/Xcode/DerivedData/iFleksy-cnieacgsclhowuapljisvitxicyg/Build/Products/Debug-iphonesimulator
FL_APPBUNDLE_PATH=~/Library/Developer/Xcode/DerivedData/iFleksy-cnieacgsclhowuapljisvitxicyg/Build/Products/Debug-iphoneos
FL_APPNAME=Fleksy.app
FL_APPBUNDLE=$FL_APPBUNDLE_PATH/$FL_APPNAME
FL_TEST_DIR=Test$FEATURE/Tests
FL_AUTOMATIONTEST_RESULTS_PATH=iFleksy_Testing/UIAutomation/Results
FL_TEST_RESULTS_DIR=Test$FEATURE

TESTRUNNER_PATH=$FL_AUTOMATIONTEST_PATH/tuneup/test_runner
TESTER=$TESTRUNNER_PATH/run

FL_TEST=Test_iFleksyTypeHelloFlickRightFlickLeft.js

echo $FL_APPNAME : $FL_TEST
echo
echo Test Driver $1 times: script $0

COUNT=0
while [ $COUNT != $1 ]
do
    echo TEST:  $COUNT 
    $TESTER $FL_APPBUNDLE $FL_AUTOMATIONTEST_PATH/$FL_TEST_DIR/$FL_TEST ../Results/$FL_TEST_RESULTS_DIR  $2 $3 --verbose --timeout 45
    sleep 1
    let COUNT=$COUNT+1
done

echo TEST Driver Cycle Completed $COUNT Runs
