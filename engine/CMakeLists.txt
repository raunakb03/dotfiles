# The shell's own C++ plugin: a QML module called MyShell.Engine.
# Build:  cmake -S engine -B engine/build && cmake --build engine/build
# Result: engine/build/qml/MyShell/Engine/ (a qmldir + the plugin .so), which Quickshell finds
#         through QML2_IMPORT_PATH=<repo>/engine/build/qml (set in Hyprland's shellCmd).
cmake_minimum_required(VERSION 3.21)
project(myshell-engine LANGUAGES CXX)

find_package(Qt6 6.9 REQUIRED COMPONENTS Core Qml)
qt_standard_project_setup(REQUIRES 6.9)

# Put every QML module under build/qml/<URI as folders>, the layout QML imports expect
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

qt_add_qml_module(myshell-engine
    URI MyShell.Engine
    VERSION 1.0
    SOURCES
        src/systemstats.hpp src/systemstats.cpp
)

# The generated type-registration code does `#include "systemstats.hpp"`, so src/ must be on the path
target_include_directories(myshell-engine PRIVATE src)
target_compile_options(myshell-engine PRIVATE -Wall -Wextra)
