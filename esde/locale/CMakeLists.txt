#  SPDX-License-Identifier: MIT
#
#  ES-DE Frontend
#  CMakeLists.txt (locale)
#
#  CMake configuration for compiling localization message catalog files using msgfmt
#

add_custom_target(localization ALL COMMENT Compiling localization message catalogs)

if(IOS)
    set(MSGFMT_BINARY ${PROJECT_SOURCE_DIR}/external/macos/local_install/bin/msgfmt)
elseif(APPLE)
    set(MSGFMT_BINARY ${PROJECT_SOURCE_DIR}/external/local_install/bin/msgfmt)
elseif(WIN32)
    set(MSGFMT_BINARY ${PROJECT_SOURCE_DIR}/external/gettext/bin/msgfmt.exe)
else()
    find_program(MSGFMT_BINARY msgfmt)
endif()

if(NOT MSGFMT_BINARY)
    message (FATAL_ERROR "Couldn't find msgfmt binary")
endif()

file(GLOB PO_FILES ${PROJECT_SOURCE_DIR}/locale/po/*.po)

if(DEFINED GAMESTICK_LOCALES AND NOT GAMESTICK_LOCALES STREQUAL "")
    string(REPLACE "," ";" GAMESTICK_LOCALES_LIST "${GAMESTICK_LOCALES}")
    set(FILTERED_PO_FILES)

    foreach(LOCALE_NAME ${GAMESTICK_LOCALES_LIST})
        set(PO_FILE ${PROJECT_SOURCE_DIR}/locale/po/${LOCALE_NAME}.po)
        if(EXISTS ${PO_FILE})
            list(APPEND FILTERED_PO_FILES ${PO_FILE})
        else()
            message(FATAL_ERROR "Missing PO file for requested locale ${LOCALE_NAME}")
        endif()
    endforeach()

    set(PO_FILES ${FILTERED_PO_FILES})
endif()

foreach (PO_FILE ${PO_FILES})
    get_filename_component(PO_FILENAME ${PO_FILE} NAME)
    get_filename_component(PO_BASENAME ${PO_FILENAME} NAME_WE)
    add_custom_command(TARGET localization POST_BUILD COMMAND echo Compiling message catalog for locale ${PO_BASENAME})
    file(MAKE_DIRECTORY ${PROJECT_SOURCE_DIR}/resources/locale/${PO_BASENAME}/LC_MESSAGES)
    add_custom_command(TARGET localization POST_BUILD COMMAND ${MSGFMT_BINARY} -c --statistics -o ${PROJECT_SOURCE_DIR}/resources/locale/${PO_BASENAME}/LC_MESSAGES/${PO_BASENAME}.mo ${PO_FILE})
endforeach()

add_custom_command(TARGET localization POST_BUILD COMMAND echo)
