cmake_minimum_required(VERSION 3.15)
project(runner LANGUAGES CXX)

if(FLUTTER_TARGET_BACKEND_TYPE MATCHES "gbm")
  add_definitions(-DFLUTTER_TARGET_BACKEND_GBM)
elseif(FLUTTER_TARGET_BACKEND_TYPE MATCHES "eglstream")
  add_definitions(-DFLUTTER_TARGET_BACKEND_EGLSTREAM)
elseif(FLUTTER_TARGET_BACKEND_TYPE MATCHES "x11")
  add_definitions(-DFLUTTER_TARGET_BACKEND_X11)
else()
  add_definitions(-DFLUTTER_TARGET_BACKEND_WAYLAND)
endif()

add_executable(${BINARY_NAME}
  "flutter_window.cc"
  "instance_manager.cc"
  "main.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)
apply_standard_settings(${BINARY_NAME})
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
# SQLite for drift: link the distro libsqlite3.so.0 so its symbols are in the
# process (pubspec.yaml sets sqlite3 `source: process`). --no-as-needed keeps the
# DT_NEEDED entry even though no C++ code here calls SQLite; push/pop-state keeps
# that flag from affecting the other libraries.
find_library(SQLITE3_LIBRARY NAMES sqlite3 REQUIRED)
target_link_libraries(${BINARY_NAME} PRIVATE
  -Wl,--push-state,--no-as-needed ${SQLITE3_LIBRARY} -Wl,--pop-state)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
target_compile_features(${BINARY_NAME} PRIVATE cxx_std_17)
add_dependencies(${BINARY_NAME} flutter_assemble)
