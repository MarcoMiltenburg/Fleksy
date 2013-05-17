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

class EmptyOutputInterface : public FleksyListenerInterface {
public:
  ~EmptyOutputInterface() {};
  
	virtual void onSetComposingText(const FLString text) {};
  /*
   * Mark a certain region of text as composing text
   */
  virtual void onSetComposingRegion(int start, int end) {};
  /*
   * Request text editor to move cursor to some position in the text
   */
  virtual void onChangeSelection(int selectionStart, int selectionEnd) {};
  /*
   * Request editor state which includes full text that is currentely in the editor and
   * selection of region. if selectionStart = selectionEnd, indicates cursor position
   * This is used to determine intital editor state
   */
  virtual FLExternalEditorState onRequestEditorState() { FLExternalEditorState s; return s;};


};

@interface FleksyClient_NOIPC : NSObject<FLUserDictionaryChangeListener> {
  
  EmptyOutputInterface* outputInterface;
  FLUserDictionary* _userDictionary;
  //NSString* languagePack;
}

- (void) loadDataWithLanguagePack:(NSString*) languagePack;

- (FLResponse*) getCandidatesForRequest:(FLRequest*) request;

@property (readonly, getter = theUserDictionary) FLUserDictionary* userDictionary;
@property SystemsIntegrator* systemsIntegrator;
@property FleksyAPI* fleksyAPI;

@end
