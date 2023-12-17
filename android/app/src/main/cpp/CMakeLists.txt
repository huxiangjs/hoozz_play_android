
# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.22.1)

# set(CMAKE_CXX_FLAGS "-Wno-error=format-security")
# INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/common)
# LINK_DIRECTORIES(/usr/local/lib)

# MLX90640
ADD_SUBDIRECTORY(${PROJECT_SOURCE_DIR}/mlx90640)
