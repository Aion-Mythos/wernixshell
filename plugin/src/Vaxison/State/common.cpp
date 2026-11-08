#include "common.hpp"

#include <qstandardpaths.h>

namespace vaxison::shell::state {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcState, "vaxison.state", QtInfoMsg)

QString stateDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericStateLocation) + u"/vaxison"_s;
}

QString monitorStateDir() {
    return stateDir() + u"/monitors"_s;
}

QString runtimeDir() {
    return QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + u"/vaxison"_s;
}

QString monitorRuntimeDir() {
    return runtimeDir() + u"/monitors"_s;
}

} // namespace vaxison::shell::state
