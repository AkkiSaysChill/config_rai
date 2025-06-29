vim.api.nvim_create_user_command("CppProject", function()
  local project_name = vim.fn.input("Project name: ")
  if project_name == "" then
    vim.notify("Project name cannot be empty", vim.log.levels.ERROR)
    return
  end

  local project_type = vim.fn.input("Type (raylib/sfml/cli): ")
  if not vim.tbl_contains({ "raylib", "sfml", "cli" }, project_type) then
    vim.notify("Invalid project type: choose raylib, sfml, or cli", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local project_path = cwd .. "/" .. project_name
  local dirs = { "/src", "/include", "/build", "/test", "/libs" }

  vim.fn.mkdir(project_path, "p")
  for _, dir in ipairs(dirs) do
    vim.fn.mkdir(project_path .. dir, "p")
  end

  if project_type == "raylib" then
    vim.notify(
      "Project directories created. Remember to place raylib, imgui, and rlimgui sources in the '"
        .. project_path
        .. "/libs' folder.",
      vim.log.levels.INFO
    )
  else
    vim.notify("Project directories created.", vim.log.levels.INFO)
  end

  -- Generate CMakeLists.txt content
  local cmake_content_base = string.format(
    [[
cmake_minimum_required(VERSION 3.12)
project(%s VERSION 0.1.0)

# Set a default build type if none is specified (e.g. Release, Debug)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build (Release, Debug, RelWithDebInfo, MinSizeRel)." FORCE)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Note: Target-specific include directories are added after add_executable()

]],
    project_name
  )

  local cmake_content = cmake_content_base
  local main_cpp_content = ""

  if project_type == "raylib" then
    cmake_content = cmake_content
      .. [[
# --- Local Libraries Setup ---
# Ensure raylib, imgui, and rlimgui sources are placed in the 'libs' directory.

# --- Raylib (from local source) ---
# Assumes raylib source code (with its own CMakeLists.txt) is in project_name/libs/raylib
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build raylib as a static library" FORCE)
set(RAYLIB_EXAMPLES OFF CACHE BOOL "Disable raylib examples" FORCE) # For raylib 5.0+
# set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE) # For older raylib versions if needed
add_subdirectory(libs/raylib) # This will create a 'raylib' target

# --- Dear ImGui & rlImGui (source files to be compiled) ---
# Assumes Dear ImGui source code is in project_name/libs/imgui
# Assumes rlImGui source code is in project_name/libs/rlimgui
list(APPEND LOCAL_LIB_SOURCES
    # Dear ImGui core files
    libs/imgui/imgui.cpp
    libs/imgui/imgui_draw.cpp
    libs/imgui/imgui_tables.cpp
    libs/imgui/imgui_widgets.cpp
    # libs/imgui/imgui_demo.cpp # Uncomment to include the ImGui demo

    # rlImGui (provides the Raylib backend for ImGui)
    libs/rlimgui/rlImGui.cpp
)

# --- Main Project Executable ---
file(GLOB MAIN_SOURCES "src/*.cpp") # User's main source files
add_executable(${PROJECT_NAME} ${MAIN_SOURCES} ${LOCAL_LIB_SOURCES})

# --- Target Specific Properties for ${PROJECT_NAME} ---
# These MUST come AFTER add_executable(${PROJECT_NAME} ...)
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include  # For project's own headers in project_name/include
    libs/imgui                           # For ImGui headers
    libs/rlimgui                         # For rlImGui headers
)

if(WIN32)
    target_link_libraries(${PROJECT_NAME} PRIVATE raylib opengl32 gdi32 winmm)
    # Optional: Add -static for MinGW static linking
    # if(CMAKE_CXX_COMPILER_ID MATCHES "GNU") # Check for MinGW
    #     target_link_options(${PROJECT_NAME} PRIVATE "-static")
    # endif()
else()
    target_link_libraries(${PROJECT_NAME} PRIVATE raylib) # Linux/other platforms
endif()
]]

    main_cpp_content = [[
#include "imgui.h"
#include "raylib.h"
#include "rlImGui.h"

int main() {
  int screenWidth = 1280;
  int screenHeight = 720;

  SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT | FLAG_MSAA_4X_HINT);
  InitWindow(screenWidth, screenHeight, "Raylib C++ ImGui Project");
  SetTargetFPS(60);

  rlImGuiSetup(true); // true: use dark theme, false: use light theme

  bool my_tool_active = true;

  while (!WindowShouldClose()) {
    BeginDrawing();
    ClearBackground(BLACK);

    // ===IMGUI===
    rlImGuiBegin(); // Start ImGui frame
    if (my_tool_active) {
      ImGui::Begin("Game Settings");

      ImGui::Text("Hello, world %d", 123);

      if (ImGui::Button("CloseWindow")) {
        my_tool_active = false;
      }

      ImGui::End();
    }
    rlImGuiEnd(); // Render ImGui draw data
    // ===================================

    EndDrawing();

    if (IsKeyPressed(KEY_M)) {
      my_tool_active = !my_tool_active;
    }
  }

  rlImGuiShutdown(); // Shutdown ImGui
  CloseWindow();
  return 0;
}]]
  elseif project_type == "sfml" then
    cmake_content = cmake_content
      .. [[

# Main Project Executable
file(GLOB MAIN_SOURCES "src/*.cpp")
add_executable(${PROJECT_NAME} ${MAIN_SOURCES})

# Target Specific Properties for ${PROJECT_NAME}
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)

find_package(SFML 2.5 COMPONENTS graphics window system REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE sfml-graphics sfml-window sfml-system)
]]
    main_cpp_content = [[
#include <SFML/Graphics.hpp>

int main() {
    sf::RenderWindow window(sf::VideoMode(800, 600), "SFML Project");
    sf::Font font;
    // Ensure arial.ttf is in your project's asset path or a system path
    if (!font.loadFromFile("arial.ttf")) {
        // Handle font loading error
        return 1;
    }

    sf::Text text("Hello, SFML!", font, 24);
    text.setFillColor(sf::Color::White);
    text.setPosition(200, 200);

    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();
        }

        window.clear();
        window.draw(text);
        window.display();
    }

    return 0;
}
]]
  else -- CLI
    cmake_content = cmake_content
      .. [[

# Main Project Executable
file(GLOB MAIN_SOURCES "src/*.cpp")
add_executable(${PROJECT_NAME} ${MAIN_SOURCES})

# Target Specific Properties for ${PROJECT_NAME}
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
]]
    main_cpp_content = [[
#include <iostream>

int main() {
    std::cout << "Hello, CLI C++ project!" << std::endl;
    return 0;
}
]]
  end

  local cmake_file_path = project_path .. "/CMakeLists.txt"
  local cmake_file = io.open(cmake_file_path, "w")
  if cmake_file then
    cmake_file:write(cmake_content)
    cmake_file:close()
  else
    vim.notify("Failed to write CMakeLists.txt to " .. cmake_file_path, vim.log.levels.ERROR)
  end

  local main_file_path = project_path .. "/src/main.cpp"
  local main_file = io.open(main_file_path, "w")
  if main_file then
    main_file:write(main_cpp_content)
    main_file:close()
  else
    vim.notify("Failed to write main.cpp to " .. main_file_path, vim.log.levels.ERROR)
  end

  vim.notify("C++ project '" .. project_name .. "' created at " .. project_path, vim.log.levels.INFO)
end, {})
