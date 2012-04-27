/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */
#include "version.h"

static const char build_version[] = SIM_VERSION_STRING ": " __DATE__ " " __TIME__;

const char *SIMVersionString()
{
    return build_version;
}