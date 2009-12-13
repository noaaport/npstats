/*
 * Copyright (c) 2005-2007 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#include <time.h>
#include "globals.h"
#include "signal.h"
#include "exec.h"
#include "manager.h"
#include "per.h"

#define PERIOD_5SECONDS		5
#define PERIOD_10SECONDS	10
#define PERIOD_HALF_MINUTE	30
#define PERIOD_MINUTE		60
#define PERIOD_5MINUTES		300
#define PERIOD_HOUR		3600
#define PERIOD_2HOURS		7200

/*
 * These are periodic events for which it does not matter exactly when they
 * are called.
 */
struct periodic_event_st {
  time_t period;
  time_t last;
  void (*proc)(void);
};

/* Events for which we must guarantee that they are called each minute. */
struct minutely_event_st {
  int last_minute;
  void (*proc)(void);
};

#define EVENT_COLLECTOR_POLL	0
#define EVENT_COLLECTOR_REPORT	1
#define EVENT_QRUNNER		2

static struct periodic_event_st gevents [] = {
  {PERIOD_10SECONDS, 0, (void*)collector_manager_poll},
  {PERIOD_MINUTE, 0, (void*)collector_manager_report},
  {PERIOD_MINUTE, 0, exec_qrunner}, 
  {0, 0, NULL}
};

#define EVENT_SCHEDULER		0
static struct minutely_event_st gmevents [] = {
  {0, exec_scheduler},
  {0, NULL}
};

static int current_minute(time_t now);

void init_periodic(void){

  struct periodic_event_st *ev = &gevents[0];
  struct minutely_event_st *mev = &gmevents[0];
  time_t now;
  int minute_now;

  now = time(NULL);
  minute_now = current_minute(now);
  while(ev->proc != NULL){
    ev->last = now;
    ++ev;
  }

  while(mev->proc != NULL){
    mev->last_minute = minute_now;
    ++mev;
  }

  /*
   * If the default periods above are changed by the configuration file
   * we use that instead.
   */
  gevents[EVENT_COLLECTOR_POLL].period = g.collector_poll_period_secs;
  gevents[EVENT_COLLECTOR_REPORT].period = g.collector_report_period_secs;
  gevents[EVENT_QRUNNER].period = g.qrunner_period_secs;
}

void periodic(void){
  /*
   * This function is called from the main loop thread.
   *
   * Call first the functions that are scheduled to run at some
   * specified intervals. Then those that should be run each time
   * periodic() is called.
   */
  struct periodic_event_st *ev = &gevents[0];
  struct minutely_event_st *mev = &gmevents[0];
  time_t now;
  int minute_now;

  now = time(NULL);
  minute_now = current_minute(now);
  while(ev->proc != NULL){
    if(now >= ev->last + ev->period){
      ev->last = now;
      ev->proc();
    }
    ++ev;
  }

  while(mev->proc != NULL){
    if(minute_now != mev->last_minute){
      mev->last_minute = minute_now;
      mev->proc();
    }
    ++mev;
  }

  /*
   * This is the mechanism used to reload the filters. Just let
   * the filter thread know it should reload the filters.
   */
  if(get_hup_flag() != 0){
    /*
     * set_reload_flag();
     */

    ;
  }
}

static int current_minute(time_t now){

  struct tm tm, *tmp;
  time_t secs;
  int minute;

  secs = now;
  tmp = localtime_r(&secs, &tm);
  minute = tmp->tm_min;

  return(minute);
}
