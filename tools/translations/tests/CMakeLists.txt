cmake_minimum_required(VERSION 3.22)
project(VehicleMessageTranslationChecks LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 REQUIRED COMPONENTS Core)
add_executable(vehicle_message_checks
    vehicle_message_checks.cpp
    ../../../src/Vehicle/VehicleMessageTranslator.cc
)
target_include_directories(vehicle_message_checks PRIVATE ../../../src/Vehicle)
target_link_libraries(vehicle_message_checks PRIVATE Qt6::Core)
if(MSVC)
    target_compile_options(vehicle_message_checks PRIVATE /utf-8)
endif()
enable_testing()
set(CATALOG_QM "" CACHE FILEPATH "Chinese QM generated with lrelease")
if(CATALOG_QM)
    add_test(NAME vehicle_message_checks COMMAND vehicle_message_checks "${CATALOG_QM}")
endif()
