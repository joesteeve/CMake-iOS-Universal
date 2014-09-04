# Copyright (c) 2014, Ruslan Baratov
# All rights reserved.

function(install_universal_ios_static_library destination)
  if(NOT APPLE)
    return()
  endif()

  if(NOT "$ENV{EFFECTIVE_PLATFORM_NAME}" MATCHES iphone)
    return()
  endif()

  if(NOT IS_ABSOLUTE "${destination}")
    message(FATAL_ERROR "`destination` is not absolute")
  endif()

  string(COMPARE EQUAL "${INSTALL_UNIVERSAL_IOS_STATIC_LIBRARY_NAME}" "" is_empty)
  if(is_empty)
    message(FATAL_ERROR "INSTALL_UNIVERSAL_IOS_STATIC_LIBRARY_NAME is empty")
  endif()
  set(target "${INSTALL_UNIVERSAL_IOS_STATIC_LIBRARY_NAME}")

  string(COMPARE EQUAL "${INSTALL_UNIVERSAL_IOS_STATIC_LIBRARY_TOP}" "" is_empty)
  if(is_empty)
    message(FATAL_ERROR "INSTALL_UNIVERSAL_IOS_STATIC_LIBRARY_TOP is empty")
  endif()
  set(work_dir "${INSTALL_UNIVERSAL_IOS_STATIC_LIBRARY_TOP}")

  string(COMPARE EQUAL "${CMAKE_INSTALL_CONFIG_NAME}" "" is_empty)
  if(is_empty)
    message(FATAL_ERROR "CMAKE_INSTALL_CONFIG_NAME is empty")
  endif()
  set(config "${CMAKE_INSTALL_CONFIG_NAME}")

  # Detect architectures
  # execute_process(
  #     COMMAND
  #     xcodebuild -sdk iphonesimulator -showBuildSettings
  #     COMMAND
  #     sed -n "s,.* VALID_ARCHS = ,,p"
  #     WORKING_DIRECTORY
  #     "${work_dir}"
  #     RESULT_VARIABLE result
  #     OUTPUT_VARIABLE IPHONESIMULATOR_ARCHS
  #     OUTPUT_STRIP_TRAILING_WHITESPACE
  # )

  # if(NOT ${result} EQUAL 0)
  #   message(FATAL_ERROR "xcodebuild failed")
  # endif()

  execute_process(
      COMMAND
      xcodebuild -sdk iphoneos -showBuildSettings
      COMMAND
      sed -n "s,.* VALID_ARCHS = ,,p"
      WORKING_DIRECTORY
      "${work_dir}"
      RESULT_VARIABLE result
      OUTPUT_VARIABLE IPHONEOS_ARCHS
      OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(NOT ${result} EQUAL 0)
    message(FATAL_ERROR "xcodebuild failed")
  endif()

  ### Library output name
  execute_process(
      COMMAND
      xcodebuild -showBuildSettings -target "${target}" -configuration "${config}"
      COMMAND
      sed -n "s,.* EXECUTABLE_NAME = ,,p"
      WORKING_DIRECTORY
      "${work_dir}"
      RESULT_VARIABLE result
      OUTPUT_VARIABLE libname
      OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(NOT ${result} EQUAL 0)
    message(FATAL_ERROR "xcodebuild failed")
  endif()

  ### Find already installed library (destination of universal library)
  set(library_destination "XXX-NOTFOUND")
  find_file(library_destination ${libname} PATHS "${destination}" NO_DEFAULT_PATH)
  if(NOT library_destination)
    message(FATAL_ERROR "Library `${libname}` not found in `${destination}`")
  endif()

  ### Build iphoneos and iphonesimulator variants
  message(STATUS "[iOS universal] Build `${target}` for `iphoneos`")

  execute_process(
      COMMAND
      "${CMAKE_COMMAND}"
      --build
      .
      --target "${target}"
      --config ${config}
      --
      -sdk iphoneos
      ONLY_ACTIVE_ARCH=NO
      "ARCHS=${IPHONEOS_ARCHS}"
      WORKING_DIRECTORY
      "${work_dir}"
      RESULT_VARIABLE
      result
  )

  if(NOT ${result} EQUAL 0)
    message(FATAL_ERROR "Build failed")
  endif()

  execute_process(
      COMMAND
      xcodebuild
      -showBuildSettings
      -target
      "${target}"
      -configuration
      "${config}"
      -sdk
      iphoneos
      COMMAND
      sed -n "s,.* CODESIGNING_FOLDER_PATH = ,,p"
      WORKING_DIRECTORY
      "${work_dir}"
      RESULT_VARIABLE result
      OUTPUT_VARIABLE iphoneos_src
      OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(NOT ${result} EQUAL 0)
    message(FATAL_ERROR "Xcode failed")
  endif()
  if(NOT EXISTS "${iphoneos_src}")
    message(FATAL_ERROR "${iphoneos_src} not found")
  endif()

  # message(STATUS "[iOS universal] Build `${target}` for `iphonesimulator`")

  # execute_process(
  #     COMMAND
  #     "${CMAKE_COMMAND}"
  #     --build
  #     .
  #     --target "${target}"
  #     --config ${config}
  #     --
  #     -sdk iphonesimulator
  #     ONLY_ACTIVE_ARCH=NO
  #     "ARCHS=${IPHONESIMULATOR_ARCHS}"
  #     WORKING_DIRECTORY
  #     "${work_dir}"
  #     RESULT_VARIABLE
  #     result
  # )

  # if(NOT ${result} EQUAL 0)
  #   message(FATAL_ERROR "Build failed")
  # endif()

  # execute_process(
  #     COMMAND
  #     xcodebuild
  #     -showBuildSettings
  #     -target
  #     "${target}"
  #     -configuration
  #     "${config}"
  #     -sdk
  #     iphonesimulator
  #     COMMAND
  #     sed -n "s,.* CODESIGNING_FOLDER_PATH = ,,p"
  #     WORKING_DIRECTORY
  #     "${work_dir}"
  #     RESULT_VARIABLE result
  #     OUTPUT_VARIABLE iphonesimulator_src
  #     OUTPUT_STRIP_TRAILING_WHITESPACE
  # )

  # if(NOT ${result} EQUAL 0)
  #   message(FATAL_ERROR "Xcode failed")
  # endif()
  # if(NOT EXISTS "${iphonesimulator_src}")
  #   message(FATAL_ERROR "${iphonesimulator_src} not found")
  # endif()

  execute_process(
      COMMAND
      lipo
      -create
      # "${iphonesimulator_src}"
      "${iphoneos_src}"
      -output ${library_destination}
      WORKING_DIRECTORY
      "${work_dir}"
      RESULT_VARIABLE result
  )

  if(NOT ${result} EQUAL 0)
    message(FATAL_ERROR "lipo failed")
  endif()

  message(STATUS "[iOS universal] Install done: ${library_destination}")
endfunction()
