//
//  FleksyClient_NOIPC.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 6/27/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SystemsIntegrator.h"
#import "FLUserDictionary.h"
#import "FleksyAPI.h"

class EmptyOutputInterface : public FLOutputInterface {
public:
  ~EmptyOutputInterface() {};
	virtual string getCurrentText() {return "";};
	virtual string getTextUpToCursor() {return "";};
  virtual string getTextAfterCursor(int numOfChars) {return "";}; //used only in one place and for testing, don't need it here?? Used in FLTextBlockCursor line: 253
	
  virtual void speak(const char* text) {};
  virtual void moveCursorToPosition(int position) {};
  virtual void beginBatchEdit() {};
  virtual void endBatchEdit() {};
  
  virtual void commitText(const char* text, int newCursorPosition) {};
  virtual void setComposingRegion(int start, int end) {};
  virtual void finishComposingText() {};
  virtual int getCursorPosition() {return 0;};
  virtual void setShift(bool shiftState) {};
  
  //For debugging
  virtual void sendErrorReport(const char *report) {}; // crazy check is using it, prob don't want it here.
  
  virtual void exit() {}; //closes fleksy application
  virtual void showToast(string message) {};
  virtual bool addRemoveWordFromDictionary(string word, bool add) {return false;};//split into two, add/remove?
  
  virtual void backSpace() {};//send backspace command to the editor
  
  virtual void endOfSuggestions() {};
  
  virtual void preparePlatformSuggestions(const char* word) {};
  
  virtual void setCandidates(vector<string> &candidates, int currCandidateIndex) {};
  virtual void setCandidateIndex(int currCandidateIndex) {};

};

@interface FleksyClient_NOIPC : NSObject<FLUserDictionaryChangeListener> {
  
  EmptyOutputInterface* outputInterface;
  FleksyAPI* fleksyAPI;
  FLUserDictionary* _userDictionary;
  //NSString* languagePack;
}

- (void) loadDataWithLanguagePack:(NSString*) languagePack;

- (FLResponse*) getCandidatesForRequest:(FLRequest*) request;

@property (readonly, getter = theUserDictionary) FLUserDictionary* userDictionary;
@property SystemsIntegrator* systemsIntegrator;

@end
