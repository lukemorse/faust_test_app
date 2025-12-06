#include "faust_c_wrapper.h"

#include <memory>

#include "ios-faust.h"

struct FaustDspHandle {
    std::unique_ptr<mydsp> dsp;
    std::unique_ptr<MapUI> ui;
};

static void faust_build_ui(FaustDspHandle* handle)
{
    handle->ui = std::unique_ptr<MapUI>(new MapUI());
    handle->dsp->buildUserInterface(handle->ui.get());
}

extern "C" {

FaustDspHandle* faust_create(int sample_rate)
{
    if (sample_rate <= 0) {
        return nullptr;
    }

    auto* handle = new FaustDspHandle();
    handle->dsp = std::unique_ptr<mydsp>(new mydsp());
    faust_build_ui(handle);
    handle->dsp->init(sample_rate);
    return handle;
}

void faust_destroy(FaustDspHandle* handle)
{
    delete handle;
}

void faust_reset(FaustDspHandle* handle, int sample_rate)
{
    if (!handle || sample_rate <= 0) {
        return;
    }

    handle->dsp->instanceResetUserInterface();
    handle->dsp->init(sample_rate);
}

void faust_process(FaustDspHandle* handle, float* output_left, float* output_right, int frame_count)
{
    if (!handle || !output_left || !output_right || frame_count <= 0) {
        return;
    }

    FAUSTFLOAT* inputs[1] = {nullptr};
    FAUSTFLOAT* outputs[2] = {output_left, output_right};
    handle->dsp->compute(frame_count, inputs, outputs);
}

int faust_get_sample_rate(FaustDspHandle* handle)
{
    return handle ? handle->dsp->getSampleRate() : 0;
}

void faust_set_parameter(FaustDspHandle* handle, const char* path, float value)
{
    if (!handle || !path) {
        return;
    }
    handle->ui->setParamValue(path, value);
}

float faust_get_parameter(FaustDspHandle* handle, const char* path)
{
    if (!handle || !path) {
        return 0.0f;
    }
    return handle->ui->getParamValue(path);
}

int faust_get_parameter_count(FaustDspHandle* handle)
{
    return handle ? handle->ui->getParamsCount() : 0;
}

int faust_get_parameter_info(
    FaustDspHandle* handle,
    int index,
    const char** path,
    const char** label,
    const char** shortname,
    float* init,
    float* min,
    float* max,
    float* step)
{
    if (!handle || index < 0 || index >= handle->ui->getParamsCount()) {
        return 0;
    }

    if (path) {
        *path = handle->ui->getParamAddress(index);
    }
    if (label) {
        *label = handle->ui->getParamLabel(index);
    }
    if (shortname) {
        *shortname = handle->ui->getParamShortname(index);
    }
    if (init) {
        *init = handle->ui->getParamInit(index);
    }
    if (min) {
        *min = handle->ui->getParamMin(index);
    }
    if (max) {
        *max = handle->ui->getParamMax(index);
    }
    if (step) {
        *step = handle->ui->getParamStep(index);
    }
    return 1;
}

} // extern "C"
