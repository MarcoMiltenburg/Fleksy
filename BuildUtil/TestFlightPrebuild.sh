#!/bin/sh

#  TestFlightPrebuild.sh
#  Fleksy
#
#  Created by John Engelhart on 3/27/13.
#  Copyright (c) 2012 Syntellia Inc. All rights reserved.

# This script needs to:
#
# Check git to see if there's any modifications that aren't commited, and abort if so.
# Do the "Edit the release notes" bit
# Increment TestFlightVersion.xcconfig by one.
# Commit and push via git the change to TestFlightVersion.xcconfig by one with a message of the release notes.
#
# If there is some kind of error, abort and roll back to pre-script run state for all state mutations.

# If any command fails, cause the script to fail and exit with non-zero status.
set -e
# If any variable is used but unset, cause the script to fail and exit with non-zero status.
set -u

# Side-stepping script until fix, see PT [#49090661]
exit 0;

if [[ ( "${CONFIGURATION}" != "TestFlight" ) ]]; then
    exit 0;
fi


# Check if there's any outstanding modifications that need to be commited, and abort if so.
#

if [[ $(git status --untracked-files=no --ignore-submodules=untracked -s) != "" ]]; then
    echo "error: There are uncomitted changes."
    exit 1;
fi

# Do the "Edit the release notes" bit.

RELEASE_NOTES_FILE=`mktemp /tmp/Release_Notes.XXXXXXXX`
printf "\n#Enter the release notes, then close the window to continue." >>${RELEASE_NOTES_FILE}
osascript -e 'tell application "Xcode"' -e 'try' -e "open \"$RELEASE_NOTES_FILE\"" -e 'activate' -e "set rndoc to open \"$RELEASE_NOTES_FILE\"" -e 'repeat while exists rndoc' -e 'delay 1' -e 'end repeat' -e 'save rndoc' -e 'on error return' -e 'end try' -e 'end tell'
#osascript -e 'tell application "Xcode"' -e 'try' -e "open \"$RELEASE_NOTES_FILE\"" -e 'activate' -e "set okButton to \"OK\"" -e "set rn_dialog to display dialog \"Enter the release notes, then close the window to continue.\" buttons {okButton} default button okButton with icon 1" -e "set rndoc to open \"$RELEASE_NOTES_FILE\"" -e 'repeat while exists rndoc' -e 'delay 1' -e 'end repeat' -e 'save rndoc' -e 'on error return' -e 'end try' -e 'end tell'
if [ "$?" -ne 0 ]; then
	exit 1
fi


# Increment TestFlightVersion.xcconfig by one.

if [ -w "${SRCROOT}/${FL_BUILDUTIL_DIR}/TestFlightVersion.xcconfig" ]; then
	/usr/bin/perl -pi -e 's/(^\s*FL_TESTFLIGHT_BUILD_NUMBER\s*=\s*)(\d+)/$1.($2+1)/eg' "${SRCROOT}/${FL_BUILDUTIL_DIR}/TestFlightVersion.xcconfig"
	if [ "$?" -ne 0 ]; then
		exit 1
	fi
else
	exit 1
fi

/usr/bin/perl -i'.orig' -e '$in=""; while(<>){$in.=$_;} $in =~ s/\n?\s*#Enter the release notes, then close the window to continue\.\n?//; print $in;' ${RELEASE_NOTES_FILE}

cd "${SRCROOT}"
if [ -r "${SRCROOT}/${FL_BUILDUTIL_DIR}/TestFlightVersion.xcconfig" ]; then
	set +e
	git commit -F "${RELEASE_NOTES_FILE}"  "${SRCROOT}/${FL_BUILDUTIL_DIR}/TestFlightVersion.xcconfig"
	if [ "$?" -ne 0 ]; then
		echo "error: Unable to commit TestFlight build."
		git checkout  "${SRCROOT}/${FL_BUILDUTIL_DIR}/TestFlightVersion.xcconfig"
		exit 1
	fi
	set -e
else
	exit 1
fi

