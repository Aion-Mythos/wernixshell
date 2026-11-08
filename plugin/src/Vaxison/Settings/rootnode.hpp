#pragma once

#include "common.hpp"
#include "objectnode.hpp"
#include "settingsfile.hpp"

namespace vaxison::shell::settings {

class RootNode : public ObjectNode {
    Q_OBJECT

    Q_PROPERTY(QList<vaxison::shell::settings::Diagnostic> diagnostics READ diagnostics NOTIFY diagnosticsChanged)

public:
    explicit RootNode(bool watch, const QString& path, RootNode* fallback, QObject* parent = nullptr);

    [[nodiscard]] QList<Diagnostic> diagnostics() const;

    void load();

signals:
    void diagnosticsChanged();
    void treeLoaded(vaxison::shell::settings::RootNode* self);
    void treeLoadFailed(vaxison::shell::settings::RootNode* self, const QString& error);
    void treeSaveFailed(vaxison::shell::settings::RootNode* self, const QString& error);

private:
    SettingsFile* const m_file;
    QList<Diagnostic> m_diagnostics;

    void reloadFromFile();
    void saveToFile();
};

} // namespace vaxison::shell::settings
