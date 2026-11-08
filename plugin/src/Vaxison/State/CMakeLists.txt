qml_module(vaxison-state
    URI Vaxison.State
    INCLUDE_PREFIX state
    SOURCES
        common.cpp
        rootnodes.cpp
    DEPENDENCIES
        Vaxison.Settings
)
target_link_libraries(vaxison-state PUBLIC vaxison-settings)
