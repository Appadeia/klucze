cmake_minimum_required(VERSION 3.1)

project(KTotp LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 COMPONENTS Core Widgets QuickControls2 Quick REQUIRED)
find_package(KF5Kirigami2)
find_package(KF5Plasma)
find_package(KF5PlasmaQuick)

add_library(cpptotp STATIC
    libcppotp/bytes.h
    libcppotp/otp.cpp
    libcppotp/bytes.cpp
    libcppotp/otp.h
    libcppotp/sha1.h
    libcppotp/sha1.cpp
)

add_executable(${PROJECT_NAME} "main.cpp" "qmltotp.cpp" "qmltotp.h" "qml.qrc")
target_compile_definitions(${PROJECT_NAME} PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(${PROJECT_NAME} PRIVATE cpptotp Qt5::Core Qt5::Widgets Qt5::QuickControls2 Qt5::Quick KF5::Plasma KF5::PlasmaQuick KF5::Kirigami2)
