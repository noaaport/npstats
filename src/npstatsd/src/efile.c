/*
 * Copyright (c) 2005 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#include <limits.h>
#include <stdio.h>
#include "err.h"
#include "file.h"
#include "efile.h"

int e_dir_exists(char *dirname){

  int status;

  status = dir_exists(dirname);

  if(status == -1)
    log_err2("Error checking %s.", dirname);
  else if(status == 1)
    log_errx("%s is not a directory.", dirname);
  else if(status == 2)
    log_errx("%s does not exist.", dirname);

  return(status);
}
