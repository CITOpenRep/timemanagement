project(NotificationsPlugin LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt5
find_package(Qt5 REQUIRED COMPONENTS Core Qml Quick DBus)

# GLib + libnotify via pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(GLIB REQUIRED glib-2.0)
pkg_check_modules(LIBNOTIFY REQUIRED libnotify)

add_library(NotificationsPlugin SHARED
    NotificationHelper.cpp
    NotificationHelper.h  
    plugin.cpp
)

# Inclure les headers de GLib/libnotify
target_include_directories(NotificationsPlugin
    PRIVATE
        ${GLIB_INCLUDE_DIRS}
        ${LIBNOTIFY_INCLUDE_DIRS}
)

# Définir les flags de compilation si pkg-config en fournit
target_compile_options(NotificationsPlugin PRIVATE
    ${GLIB_CFLAGS_OTHER}
    ${LIBNOTIFY_CFLAGS_OTHER}
)

# Lier Qt + DBus + Glib + libnotify
target_link_libraries(NotificationsPlugin
    PRIVATE
        Qt5::Core
        Qt5::Qml
        Qt5::Quick
        Qt5::DBus
        ${GLIB_LIBRARIES}
        ${LIBNOTIFY_LIBRARIES}
)

# Installation dans le chemin QML
install(TARGETS NotificationsPlugin
        LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/qml-plugins/Pparent/Notifications)

install(FILES qmldir
        DESTINATION ${CMAKE_INSTALL_PREFIX}/qml-plugins/Pparent/Notifications)
