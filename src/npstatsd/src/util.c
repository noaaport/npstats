/*
 * Copyright (c) 2005-2008 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#include <stddef.h>
#include <string.h>
#include <ctype.h>
#include "util.h"

int valid_str(char *s){

  if((s != NULL) && (s[0] != '\0'))
    return(1);

  return(0);
}

char *trimleft(char *s, char *t){

  char *p = s;

  if(t == NULL){
    while(isspace(*p))
      ++p;
  } else {
    while((strchr(t, *p) != NULL) && (*p != '\0'))
      ++p;
  }

  if(*p == '\0')
    return(s);

  return(p);
}

char *trimright(char *s, char *t){
  /*
   * Note: This function modifies the "s" argument.
   */
  char *q;
  size_t size;

  size = strlen(s);
  if(size == 0)
    return(s);

  q = &s[size - 1];

  if(t == NULL){
    while(isspace(*q) && (q != s)){
      *q = '\0';
      --q;
    }
  } else {
    while((strchr(t, *q) != NULL) && (q != s)){
      *q = '\0';
      --q;
    }
  }

  return(s);
}
