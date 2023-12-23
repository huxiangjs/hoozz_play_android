
# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.22.1)

# Declares and names the project.

project("remote_sw" LANGUAGES C CXX)

# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.

add_library( # Sets the name of the library.
             remote_sw

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             git_things/src/gitt_ssh.c
             git_things/src/gitt_sha1.c
             git_things/src/gitt_unpack.c
             git_things/src/gitt_misc.c
             git_things/src/gitt_zlib.c
             git_things/src/gitt_command.c
             git_things/src/gitt_repository.c
             git_things/src/gitt_commit.c
             git_things/src/gitt_pack.c
             git_things/src/gitt.c
             git_things/third_party/zlib/adler32.c
             git_things/third_party/zlib/crc32.c
             git_things/third_party/zlib/deflate.c
             git_things/third_party/zlib/inffast.c
             git_things/third_party/zlib/inflate.c
             git_things/third_party/zlib/inftrees.c
             git_things/third_party/zlib/trees.c
             git_things/third_party/zlib/zutil.c
             gitt_log_impl.c
             gitt_ssh_impl.c
             remote_sw.c
)

# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

find_library( # Sets the name of the path variable.
              log-lib

              # Specifies the name of the NDK library that
              # you want CMake to locate.
              log )

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

target_link_libraries( # Specifies the target library.
                       remote_sw

                       # Links the target library to the log library
                       # included in the NDK.
                       ${log-lib} )

include_directories(
             ./
             ./git_things/include/
)
