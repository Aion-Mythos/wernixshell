cmake_minimum_required(VERSION 3.19)

if(NOT DEFINED VERSION)
    execute_process(COMMAND git describe --tags --abbrev=0
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if("${VERSION}" STREQUAL "")
        message(FATAL_ERROR "VERSION is not set and failed to get from git")
    endif()
endif()

if(NOT DEFINED GIT_REVISION)
    execute_process(COMMAND git rev-parse HEAD
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE GIT_REVISION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if("${GIT_REVISION}" STREQUAL "")
        message(FATAL_ERROR "GIT_REVISION is not set and failed to get from git")
    endif()
endif()

string(REGEX REPLACE "^v" "" VERSION "${VERSION}")

project(wernixshell VERSION ${VERSION} LANGUAGES CXX)

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

set(DISTRIBUTOR "Unset" CACHE STRING "Distributor")
set(ENABLE_MODULES "extras;plugin;shell" CACHE STRING "Modules to build/install")
set(INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}/wernixshell" CACHE STRING "Library install dir")
set(INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml" CACHE STRING "QML install dir")
set(INSTALL_QSCONFDIR "${CMAKE_INSTALL_SYSCONFDIR}/xdg/quickshell/wernixshell" CACHE STRING "Quickshell config install dir")

add_compile_definitions(
    QT_NO_CAST_FROM_ASCII
    QT_NO_CAST_TO_ASCII
    QT_NO_CAST_FROM_BYTEARRAY
)

add_compile_options(
    -Wall -Wextra -Wpedantic -Wshadow -Wconversion
    -Wold-style-cast -Wnull-dereference -Wdouble-promotion
    -Wformat=2 -Wfloat-equal -Woverloaded-virtual
    -Wsign-conversion -Wredundant-decls -Wswitch
    -Wunreachable-code
)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wunused-lambda-capture -Wno-nonportable-include-path)
endif()

if("extras" IN_LIST ENABLE_MODULES)
    add_subdirectory(extras)
endif()

if("plugin" IN_LIST ENABLE_MODULES)
    add_subdirectory(plugin)
endif()

option(ENABLE_GLASS "Build the bundled hyprglass Hyprland plugin (the Liquid glass setting)" ON)
if(ENABLE_GLASS)
    # hyprglass builds inside its source tree, so build a copy of the submodule
    set(GLASS_SRC "${CMAKE_SOURCE_DIR}/third_party/hyprglass")
    set(GLASS_SO "${CMAKE_BINARY_DIR}/lib/hyprglass.so")
    if(NOT EXISTS "${GLASS_SRC}/Makefile")
        message(FATAL_ERROR "third_party/hyprglass is missing: run git submodule update --init, or pass -DENABLE_GLASS=OFF")
    endif()
    include(ProcessorCount)
    ProcessorCount(GLASS_JOBS)
    add_custom_command(
        OUTPUT "${GLASS_SO}"
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${GLASS_SRC}" "${CMAKE_BINARY_DIR}/hyprglass"
        COMMAND make -C "${CMAKE_BINARY_DIR}/hyprglass" -j${GLASS_JOBS} HYPRGLASS_VERSION=wernixshell
        COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_BINARY_DIR}/hyprglass/hyprglass.so" "${GLASS_SO}"
        DEPENDS "${GLASS_SRC}/Makefile"
        VERBATIM
    )
    add_custom_target(hyprglass ALL DEPENDS "${GLASS_SO}")
    install(FILES "${GLASS_SO}" DESTINATION "${INSTALL_LIBDIR}")
endif()

if("shell" IN_LIST ENABLE_MODULES)
    foreach(dir assets components daemons data modules services utils)
        install(DIRECTORY ${dir} DESTINATION "${INSTALL_QSCONFDIR}")
    endforeach()

    install(PROGRAMS assets/wrap_term_launch.sh DESTINATION "${INSTALL_QSCONFDIR}/assets")

    file(READ shell.qml SHELL_QML)
    string(REPLACE "settings.watchFiles: true" "settings.watchFiles: false" SHELL_QML "${SHELL_QML}")
    file(WRITE "${CMAKE_BINARY_DIR}/qml/shell.qml" "${SHELL_QML}")
    install(FILES "${CMAKE_BINARY_DIR}/qml/shell.qml" DESTINATION "${INSTALL_QSCONFDIR}")

    install(FILES LICENSE DESTINATION "${INSTALL_QSCONFDIR}")
endif()
