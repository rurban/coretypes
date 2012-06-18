/*    -*- mode:C c-basic-offset:4 -*-
 *
 *    dual-life parts for 5.18 coretypes:
 *    if defined PERL_CORE we assume a fast patched parser and sv in core,
 *    else we use slow back-compat parser hooks, and tie magic to access the data.
 *
 *    Copyright (C) 2012 by Reini Urban
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef PERL_CORE
 #define INTERNAL_CORE_IMPLEMENTATION 1
#else
 #define INTERNAL_CORE_IMPLEMENTATION 0
#endif


MODULE=coretypes 	PACKAGE=coretypes

PROTOTYPES: DISABLE

BOOT:
	sv_setsv(get_sv("coretypes::_PERL_CORE", GV_ADD), newSViv(INTERNAL_CORE_IMPLEMENTATION));
