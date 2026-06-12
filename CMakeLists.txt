cmake_minimum_required(VERSION 3.16)
project(crow-hello CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)
FetchContent_Declare(
    Crow
    GIT_REPOSITORY https://github.com/CrowCpp/Crow.git
    GIT_TAG        v1.2.0
)
set(CROW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(CROW_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(Crow)

add_executable(crow-hello src/main.cpp)
target_link_libraries(crow-hello PRIVATE Crow::Crow)
