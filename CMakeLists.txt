cmake_minimum_required(VERSION 3.0.0)
project(timemanagementapp C CXX)

# Automatically create moc files
set(CMAKE_AUTOMOC ON)

find_package(Qt5 REQUIRED COMPONENTS Core Qml Quick DBus)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GLIB REQUIRED glib-2.0)
pkg_check_modules(LIBNOTIFY REQUIRED libnotify)

execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_MULTIARCH
    OUTPUT_VARIABLE ARCH_TRIPLET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(QT_IMPORTS_DIR "lib/${ARCH_TRIPLET}")

add_subdirectory(qml-notify-module)

set(PROJECT_NAME "ubtms")
set(FULL_PROJECT_NAME "ubtms")
set(DATA_DIR /)
set(DESKTOP_FILE_NAME ${PROJECT_NAME}.desktop)

# This command figures out the minimum SDK framework for use in the manifest
# file via the environment variable provided by Clickable or sets a default value otherwise.
if(DEFINED ENV{SDK_FRAMEWORK})
    set(CLICK_FRAMEWORK "$ENV{SDK_FRAMEWORK}")
else()
    set(CLICK_FRAMEWORK "ubuntu-sdk-20.04")
endif()

# This figures out the target architecture for use in the manifest file.
if(DEFINED ENV{ARCH})
    set(CLICK_ARCH "$ENV{ARCH}")
else()
    execute_process(
        COMMAND dpkg-architecture -qDEB_HOST_ARCH
        OUTPUT_VARIABLE CLICK_ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif()

configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES ${PROJECT_NAME}.apparmor DESTINATION ${DATA_DIR})
install(FILES ubtms-push.apparmor DESTINATION ${DATA_DIR})
install(FILES ubtms-push-helper.json DESTINATION ${DATA_DIR})
install(FILES ubtms-urls.json DESTINATION ${DATA_DIR})
install(PROGRAMS push-helper.py DESTINATION ${DATA_DIR})
install(PROGRAMS start-daemon.sh DESTINATION ${DATA_DIR})
install(FILES ubtms-daemon.desktop DESTINATION ${DATA_DIR})

install(DIRECTORY assets DESTINATION ${DATA_DIR})
install(DIRECTORY src DESTINATION ${DATA_DIR})

install(DIRECTORY qml DESTINATION ${DATA_DIR})
install(DIRECTORY models DESTINATION ${DATA_DIR})
install(DIRECTORY voice_to_text DESTINATION ${DATA_DIR} PATTERN "model" EXCLUDE)


# Map Clickable architecture to Pip platform tags
if(CLICK_ARCH STREQUAL "arm64")
    set(PIP_PLATFORM "manylinux2014_aarch64")
elseif(CLICK_ARCH STREQUAL "amd64")
    set(PIP_PLATFORM "manylinux2014_x86_64")
else()
    set(PIP_PLATFORM "manylinux2014_${CLICK_ARCH}")
endif()

# Detect Python version and ABI for pip dependencies
execute_process(
    COMMAND python3 -c "import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))"
    OUTPUT_VARIABLE PYTHON_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
    COMMAND python3 -c "import sys; print('cp{}{}'.format(sys.version_info.major, sys.version_info.minor))"
    OUTPUT_VARIABLE PYTHON_ABI
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Dynamically download python dependencies during build
if(CLICK_ARCH STREQUAL "armhf")
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/voice_deps_installed.stamp
        COMMAND rm -rf ${CMAKE_CURRENT_BINARY_DIR}/voice_to_text/lib
        COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/voice_to_text/lib
        COMMAND touch ${CMAKE_CURRENT_BINARY_DIR}/voice_deps_installed.stamp
        COMMENT "Skipping voice-to-text Python dependencies on armhf (unsupported architecture)"
    )
else()
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/voice_deps_installed.stamp
        # Clean the build-time lib directory to ensure a fresh install
        COMMAND rm -rf ${CMAKE_CURRENT_BINARY_DIR}/voice_to_text/lib
        COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/voice_to_text/lib
        # 1. Download all dependencies with the correct architecture/platform tags
        COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/python_downloads
        # Download binary packages (force aarch64)
        # We use --no-deps to prevent it from trying to resolve pure-python dependencies with platform tags
        COMMAND python3 -m pip download --dest ${CMAKE_CURRENT_BINARY_DIR}/python_downloads
                --platform ${PIP_PLATFORM} --python-version ${PYTHON_VERSION} --implementation cp --abi ${PYTHON_ABI} --only-binary=:all: --no-deps
                vosk==0.3.45 cffi==1.17.1 websockets==13.1 charset-normalizer==3.4.7
        # Download pure-python packages (no platform tags needed as they are none-any)
        COMMAND python3 -m pip download --dest ${CMAKE_CURRENT_BINARY_DIR}/python_downloads
                certifi==2024.2.2 idna==3.13 requests==2.31.0 srt==3.5.3 tqdm==4.67.3 urllib3==1.26.18 pycparser

        # 2. Install the downloaded packages into the target lib folder
        # Phase 1: Binary ones (force platform). Use --no-deps to skip resolution of pure-python deps.
        COMMAND python3 -m pip install --target ${CMAKE_CURRENT_BINARY_DIR}/voice_to_text/lib 
                --no-index --find-links=${CMAKE_CURRENT_BINARY_DIR}/python_downloads
                --platform ${PIP_PLATFORM} --python-version ${PYTHON_VERSION} --implementation cp --abi ${PYTHON_ABI} --only-binary=:all: --no-deps
                vosk==0.3.45 cffi==1.17.1 websockets==13.1 charset-normalizer==3.4.7
        # Phase 2: Pure-python ones. We also use --no-deps here to be safe and specific.
        COMMAND python3 -m pip install --target ${CMAKE_CURRENT_BINARY_DIR}/voice_to_text/lib 
                --no-index --find-links=${CMAKE_CURRENT_BINARY_DIR}/python_downloads --no-deps
                certifi==2024.2.2 idna==3.13 requests==2.31.0 srt==3.5.3 tqdm==4.67.3 urllib3==1.26.18 pycparser

        # 3. Bundle libatomic.so.1 (required by vosk on some arm64 devices)
        # It's installed in the container via dependencies_target in clickable.yaml
        COMMAND cp /usr/lib/${ARCH_TRIPLET}/libatomic.so.1 ${CMAKE_CURRENT_BINARY_DIR}/voice_to_text/lib/ || true
        COMMAND touch ${CMAKE_CURRENT_BINARY_DIR}/voice_deps_installed.stamp
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/voice_to_text/requirements.txt
        COMMENT "Installing Python dependencies for voice to text (${CLICK_ARCH})"
    )
endif()
add_custom_target(install_voice_deps ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/voice_deps_installed.stamp)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/voice_to_text/lib DESTINATION voice_to_text)

# Translations
file(GLOB_RECURSE I18N_SRC_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/po qml/*.qml qml/*.js)
list(APPEND I18N_SRC_FILES ${DESKTOP_FILE_NAME}.in.h)

find_program(INTLTOOL_MERGE intltool-merge)
if(NOT INTLTOOL_MERGE)
    message(FATAL_ERROR "Could not find intltool-merge, please install the intltool package")
endif()
find_program(INTLTOOL_EXTRACT intltool-extract)
if(NOT INTLTOOL_EXTRACT)
    message(FATAL_ERROR "Could not find intltool-extract, please install the intltool package")
endif()

add_custom_target(${DESKTOP_FILE_NAME} ALL
    COMMENT "Merging translations into ${DESKTOP_FILE_NAME}..."
    COMMAND LC_ALL=C ${INTLTOOL_MERGE} -d -u ${CMAKE_SOURCE_DIR}/po ${CMAKE_SOURCE_DIR}/${DESKTOP_FILE_NAME}.in ${DESKTOP_FILE_NAME}
    COMMAND sed -i 's/${PROJECT_NAME}-//g' ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE_NAME}
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE_NAME} DESTINATION ${DATA_DIR})


add_subdirectory(po)

# Make source files visible in qtcreator
file(GLOB_RECURSE PROJECT_SRC_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    qml/*.qml
    models/*.js
    src/*
    *.json
    *.json.in
    *.apparmor
    *.desktop.in
)

add_custom_target(${PROJECT_NAME}_FILES ALL SOURCES ${PROJECT_SRC_FILES})

