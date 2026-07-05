cmake_minimum_required(VERSION 3.10)
project(pty)

add_library(pty SHARED
    ../c/pty.c
)

target_include_directories(pty PRIVATE ../c)

find_library(log-lib log)
target_link_libraries(pty ${log-lib})
