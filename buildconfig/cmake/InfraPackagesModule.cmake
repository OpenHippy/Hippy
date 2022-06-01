#
# Tencent is pleased to support the open source community by making
# Hippy available.
#
# Copyright (C) 2022 THL A29 Limited, a Tencent company.
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

cmake_minimum_required(VERSION 3.14)

include(FetchContent)

set(INFA_PACKAGES_URL "https://hippy-packages-1258344701.cos.accelerate.myqcloud.com")
set(DEFAULT_INFA_DOMAIN "hippy")

macro(InfaPackage_Add packageName)
    string(TOLOWER ${ARGV0} packageNameLower)
    if("${packageNameLower}" STREQUAL "")
        message(FATAL_ERROR "Empty packageName not allowed for InfaPackage_Add()")
    endif()

    set(requiredValueArgs REMOTE LOCAL)
    set(optionalValueArgs REMOTE_HASH REMOTE_DOMAIN)

    set(options "")
    set(oneValueArgs ${requiredValueArgs} ${optionalValueArgs})
    set(multiValueArgs "")
    set(list_var "${ARGN}")
    cmake_parse_arguments(ARG
            "${options}" "${oneValueArgs}" "${multiValueArgs}" ${list_var})

    if (NOT ARG_REMOTE_DOMAIN)
        set(ARG_REMOTE_DOMAIN ${DEFAULT_INFA_DOMAIN})
    endif()
    foreach(__item IN LISTS requiredValueArgs)
        if ("${ARG_${__item}}" STREQUAL "")
            message(FATAL_ERROR "Missing ${__item} argument when calling InfaPackage_Add()")
        endif()
    endforeach()

    set(ABSOLUTE_LOCAL_PATH "${ARG_LOCAL}")
    if (NOT IS_ABSOLUTE "${ABSOLUTE_LOCAL_PATH}")
        get_filename_component(ABSOLUTE_LOCAL_PATH "${ABSOLUTE_LOCAL_PATH}" ABSOLUTE)
    endif()
    if (EXISTS "${ABSOLUTE_LOCAL_PATH}")
        # Pass variables back to the caller.
        set(${packageNameLower}_SOURCE_DIR ${ABSOLUTE_LOCAL_PATH})
        if ("${ABSOLUTE_LOCAL_PATH}" MATCHES "^${CMAKE_SOURCE_DIR}")
            set(${packageNameLower}_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${ARG_LOCAL}")
        else()
            set(${packageNameLower}_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/infa_packages/${packageNameLower}")
        endif()
        set(${contentNameLower}_POPULATED True)

        if (EXISTS "${ABSOLUTE_LOCAL_PATH}/CMakeLists.txt")
            add_subdirectory(${ABSOLUTE_LOCAL_PATH} ${${packageNameLower}_BINARY_DIR})
        endif()
    else()
        # Prepare FetchContent_Declare() ARG
        set(FetchContent_Declare_ARG ${packageNameLower}
                URL "${INFA_PACKAGES_URL}/${ARG_REMOTE_DOMAIN}/${ARG_REMOTE}")
        if (ARG_REMOTE_HASH)
            list(APPEND FetchContent_Declare_ARG URL_HASH ${ARG_REMOTE_HASH})
        endif()

        FetchContent_Declare(${FetchContent_Declare_ARG})
        FetchContent_MakeAvailable(${packageNameLower})
    endif()
endmacro()