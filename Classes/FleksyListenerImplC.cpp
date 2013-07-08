
//#if FLEKSY_API_TESTING

#include "FleksyListenerImplC.h"

using namespace std;

FleksyListenerImplC::FleksyListenerImplC() {
  text = "";
  composingEnd = 0;
  composingStart = 0;
}

void FleksyListenerImplC::onSetComposingText(const FLString text){
  int n = composingEnd - composingStart;
  
  if(composingStart != composingEnd){
    state.text.erase(composingStart, n);
  }
  state.text.insert(composingStart, text);
  
  composingStart = composingEnd;

  //printf(" ***** FleksyAPI Testing :SCREEN:<%s> \n", state.text.c_str());
}

void FleksyListenerImplC::onSetComposingRegion(int start, int end){
  composingStart = start;
  composingEnd = end;
}

void FleksyListenerImplC::onChangeSelection(int selectionStart, int selectionEnd){
  composingStart = selectionStart;
  composingEnd = selectionEnd;
}

FLExternalEditorState FleksyListenerImplC::onRequestEditorState(){
  return state;
}

//#endif
