#!/bin/sh

echo command: $0 $1 

: ${1?"USAGE: $0 <results_text_file>"}

if [ -f $1 ]
then
echo Parsing results for $1 Test
else
echo $1 "does not exist"
exit 1
fi
pwd

echo 'grep "TEST PASSED" $1 | wc -l'
grep "TEST PASSED" $1 | wc -l

echo 'grep "TEST FAIL" $1 | wc -l'
grep "TEST FAIL" $1 | wc -l

echo 'grep "END OF LOOP" $1 | wc -l'
grep "END OF LOOP" $1 | wc -l

echo 'grep "END OF RUN" $1 | wc -l'
grep "END OF RUN" $1 | wc -l

echo 'grep "1 tests, 0 failures" $1 | wc -l'
grep "1 tests, 0 failures" $1 | wc -l

echo 'grep "1 tests, 1 failures" $1 | wc -l'
grep "1 tests, 1 failures" $1 | wc -l

echo 'grep "js failed" $1 | wc -l'
grep "js failed" $1 | wc -l

echo 'grep "Fail: The target application appears to have died" $1 | wc -l'
grep "Fail: The target application appears to have died" $1 | wc -l

echo 'grep "Instruments exited unexpectedly" $1 | wc -l'
grep "Instruments exited unexpectedly" $1 | wc -l

echo END OF PARSER
