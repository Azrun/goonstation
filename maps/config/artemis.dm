#ifdef MAP_OVERRIDE_ARTEMIS
//#warn Only using ARTEMIS z-levels. This will fuck everything up. You're gonna have a bad time.
#include "..\atlas.dmm"
#define MAP_MODE "standard"
#endif

#ifdef ENABLE_ARTEMIS
//#warn ARTEMIS ARTEMIS ARTEMIS ARTEMIS ARTEMIS ARTEMIS ARTEMIS ARTEMIS ARTEMIS ARTEMIS
#include "..\artemis\planets.dmm"
#else
#error ARTEMIS IS NOT ENABLED!!!!!!
#endif
