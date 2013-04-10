//
//  FleksyListenerImplC.h
//  FleksySample1
//
//  Created by Vadim Maximov on 3/22/13.
//  Copyright (c) 2013 Syntellia. All rights reserved.
//

#ifndef __FleksySample1__FleksyListenerImplC__
#define __FleksySample1__FleksyListenerImplC__

#include "Fleksy.h"

class FleksyListenerImplC: public FleksyListenerInterface{
public:
  FleksyListenerImplC();
  void onSetComposingText(const FLString text);
  void onSetComposingRegion(int start, int end);
  void onChangeSelection(int selectionStart, int selectionEnd);
  FLExternalEditorState onRequestEditorState();
  
  // below methods are optional:
  //    void onSpeak(const FLString text);
  //    void onBeginBatchEdit();
  //    void onEndBatchEdit();
  //    void onCaseChanged(bool upperCase);
  //    void onDictionaryModified(FLDictionaryChangeEvent event, FLString word);
  //    void onReceiveSuggestions(std::vector<FLString> suggestions, int selectedIndex);
  //    void onSelectedSuggestionChanged(int selectedIndex);
  //    void onMessageReceived(FLMessageType type, FLString message);
  //    void onRequestAdditionalSuggestions(const FLString rawText);

private:
  std::string text;
  FLExternalEditorState state;
  int composingEnd = 0;
  int composingStart = 0;
};

#endif /* defined(__FleksySample1__FleksyListenerImplC__) */
