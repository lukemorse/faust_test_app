#ifndef FAUST_C_WRAPPER_H
#define FAUST_C_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

// Opaque handle for the Faust DSP instance.
typedef struct FaustDspHandle FaustDspHandle;

/**
 * Create and initialize the Faust DSP.
 * @param sample_rate Target sample rate for initialization.
 * @return Opaque handle, or nullptr on failure.
 */
FaustDspHandle* faust_create(int sample_rate);

/**
 * Destroy a handle created by faust_create.
 */
void faust_destroy(FaustDspHandle* handle);

/**
 * Reinitialize the DSP at a new sample rate and reset its state/UI defaults.
 */
void faust_reset(FaustDspHandle* handle, int sample_rate);

/**
 * Render audio into two output buffers (stereo).
 * Inputs are ignored because the generated DSP has no inputs.
 */
void faust_process(FaustDspHandle* handle, float* output_left, float* output_right, int frame_count);

/**
 * Return the sample rate currently configured on the DSP.
 */
int faust_get_sample_rate(FaustDspHandle* handle);

/**
 * Set a parameter by its label/path/shortname (e.g., "Pitch").
 */
void faust_set_parameter(FaustDspHandle* handle, const char* path, float value);

/**
 * Get a parameter by its label/path/shortname (e.g., "Pitch").
 */
float faust_get_parameter(FaustDspHandle* handle, const char* path);

/**
 * Expose the number of controllable parameters.
 */
int faust_get_parameter_count(FaustDspHandle* handle);

/**
 * Fetch metadata for a parameter index. Returns 0 on failure.
 * Pointers reference internal strings valid for the lifetime of the handle.
 */
int faust_get_parameter_info(
    FaustDspHandle* handle,
    int index,
    const char** path,
    const char** label,
    const char** shortname,
    float* init,
    float* min,
    float* max,
    float* step);

#ifdef __cplusplus
}
#endif

#endif // FAUST_C_WRAPPER_H
