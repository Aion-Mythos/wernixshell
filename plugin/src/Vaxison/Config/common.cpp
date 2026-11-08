#include "common.hpp"

#include <qstandardpaths.h>

namespace vaxison::shell::config {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcConfig, "vaxison.config", QtInfoMsg)

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/vaxison"_s;
}

QString monitorConfigDir() {
    return configDir() + u"/monitors"_s;
}

} // namespace vaxison::shell::config
