qml_module(vaxison-models
    URI Vaxison.Models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
    LIBRARIES
        Qt::Gui
        Qt::Multimedia
        Qt::Concurrent
        Qt::Sql
)
