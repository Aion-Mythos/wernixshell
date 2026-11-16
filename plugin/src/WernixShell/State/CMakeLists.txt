qml_module(wernixshell-state
    URI WernixShell.State
    INCLUDE_PREFIX state
    SOURCES
        common.cpp
        rootnodes.cpp
    DEPENDENCIES
        WernixShell.Settings
)
target_link_libraries(wernixshell-state PUBLIC wernixshell-settings)
