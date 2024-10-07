/*
 * Copyright (c) 2009 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#ifndef GLOBALS_H
#define GLOBALS_H

#include <sys/stat.h>

struct npstatsd_globals {
  char *defconfigfile;  /* the default */
  char *configfile;     /* user-specified (via -c) */
  int   option_C;       /* [-C] just print configuration and exit */
  int   option_F;	/* [-F] don't call daemon() */
  /*
   * configurable options 
   */
  char *user;
  char *group;
  char *home;
  mode_t umask;
  char *pidfile;
  mode_t pidfile_mode;
  char *startscript;
  char *stopscript;
  char *scheduler;
  int collector_manager_enable;
  char *collector_manager;
  int collector_poll_period_secs;
  int collector_report_period_secs;
  int qrunner_enable;
  char *qrunner;
  int qrunner_period_secs;
  int httpd_enable;
  char *httpd;
  /*
   * variables
   */
  int f_debug;
  int f_verbose;
  int f_lock;	/* pid file created or not */
  int f_ndaemon;
  /*
   * test
   */
  int report_test1_period_s;
  int report_test2_period_s;
};

/*
 * Oct 2024 - This not is borrowed from nbsp -
 *
  June 2022 - Added this note (for debian 11) because gcc was complaining
  about multiple defintions of "g".

  [https://stackoverflow.com/questions/69908418/ \
  multiple-definition-of-first-defined-here-on-gcc-10-2-1-but-not-gcc-8-3-0]

  In C a definition of a global variable that does not initialise the variable
  is considered "tentative". You can have multiple tentative definitions of a
  variable in the same compilation unit. Multiple tentative defintions in
  different compilation units are not allowed in standard C, but were
  historically allowed by C compilers on unix systems.

  Older versions of gcc would allow multiple tenative definitions (but not
  multiple non-tentative definitions) of a global variable in different
  compilation units by default. gcc-10 does not. You can restore the old
  behavior with the command line option "-fcommon" but this is discouraged.
*/

/* 
 * June 2022 - to solve the above problem added this
 * (and defined NBSP_GLOBALS_DEF in main.c and nowehere else)
 */
#ifdef NPSTATSD_GLOBALS_DEF
struct npstatsd_globals g;
#else
extern struct npstatsd_globals g;
#endif

#endif
