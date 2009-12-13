/*
 * Copyright (c) 2009 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#ifndef COLLECTOR_MANAGER_H
#define COLLECTOR_MANAGER_H

int collector_manager_open(void);
void collector_manager_close(void);
int collector_manager_poll(void);
int collector_manager_report(void);

#endif
