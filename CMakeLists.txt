cmake_minimum_required(VERSION 3.16)
project(cutie-sysmonitor VERSION 1.0 LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml LinguistTools)

qt_standard_project_setup()

set(cutie-sysmonitor_SOURCES
        src/main.cpp
        src/systemmonitor.cpp
        src/systemmonitor.h
)

qt_add_resources(APP_RESOURCES
	${CMAKE_SOURCE_DIR}/src/qml/qml.qrc)

qt_add_executable(cutie-sysmonitor ${cutie-sysmonitor_SOURCES} ${APP_RESOURCES})

qt_add_translations(cutie-sysmonitor
    TS_FILES ${CMAKE_SOURCE_DIR}/translations/cutie-sysmonitor_fi.ts)

target_include_directories(cutie-sysmonitor PUBLIC src)

target_link_libraries(cutie-sysmonitor PUBLIC Qt::Core Qt::Quick Qt::Qml)

install(TARGETS cutie-sysmonitor RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES cutie-sysmonitor.desktop DESTINATION "${CMAKE_INSTALL_DATADIR}/applications")
install(FILES cutie-sysmonitor.svg DESTINATION "${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps")
