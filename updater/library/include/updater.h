#ifndef updater_h
#define updater_h

/* Warning, this file is autogenerated by cbindgen. Don't modify this manually. */

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#ifdef _WIN32
#define SHOREBIRD_EXPORT __declspec(dllexport)
#else
#define SHOREBIRD_EXPORT __attribute__((visibility("default")))
#endif


/**
 * Struct containing configuration parameters for the updater.
 * Passed to all updater functions.
 * NOTE: If this struct is changed all language bindings must be updated.
 */
typedef struct AppParameters {
  /**
   * release_version, required.  Named version of the app, off of which updates
   * are based.  Can be either a version number or a hash.
   */
  const char *release_version;
  /**
   * Path to the original aot library, required.  For Flutter apps this
   * is the path to the bundled libapp.so.  May be used for compression
   * downloaded artifacts.
   */
  const char *original_libapp_path;
  /**
   * Path to the app's libflutter.so, required.  May be used for ensuring
   * downloaded artifacts are compatible with the Flutter/Dart versions
   * used by the app.  For Flutter apps this should be the path to the
   * bundled libflutter.so.  For Dart apps this should be the path to the
   * dart executable.
   */
  const char *vm_path;
  /**
   * Path to cache_dir where the updater will store downloaded artifacts.
   */
  const char *cache_dir;
} AppParameters;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/**
 * Configures updater.  First parameter is a struct containing configuration
 * from the running app.  Second parameter is a YAML string containing
 * configuration compiled into the app.
 */
SHOREBIRD_EXPORT
void shorebird_init(const struct AppParameters *c_params,
                    const char *c_yaml);

/**
 * Return the active patch number, or NULL if there is no active patch.
 */
SHOREBIRD_EXPORT char *shorebird_active_patch_number(void);

/**
 * Return the path to the active patch for the app, or NULL if there is no
 * active patch.
 */
SHOREBIRD_EXPORT char *shorebird_active_path(void);

/**
 * Free a string returned by the updater library.
 */
SHOREBIRD_EXPORT void shorebird_free_string(char *c_string);

/**
 * Check for an update.  Returns true if an update is available.
 */
SHOREBIRD_EXPORT bool shorebird_check_for_update(void);

/**
 * Synchronously download an update if one is available.
 */
SHOREBIRD_EXPORT void shorebird_update(void);

/**
 * Report that the app failed to launch.  This will cause the updater to
 * attempt to roll back to the previous version if this version has not
 * been launched successfully before.
 */
SHOREBIRD_EXPORT void shorebird_report_failed_launch(void);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

#endif /* updater_h */
