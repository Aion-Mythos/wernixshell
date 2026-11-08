qml_module(vaxison-settings
    URI Vaxison.Settings
    INCLUDE_PREFIX settings
    SOURCES
        common.cpp
        schema.cpp
        codecs.cpp
        quarantine.cpp
        node.cpp
        objectnode.cpp
        listnode.cpp
        rootnode.cpp
        settingsfile.cpp
        changebatcher.cpp
    LIBRARIES
        vaxison-util
)
