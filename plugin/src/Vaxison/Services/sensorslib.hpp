#pragma once

#include <optional>

namespace vaxison::shell::services::sensorslib {

void ensureInit();

[[nodiscard]] std::optional<double> cpuPackageTemp();
[[nodiscard]] std::optional<double> gpuPciAverageTemp();

} // namespace vaxison::shell::services::sensorslib
