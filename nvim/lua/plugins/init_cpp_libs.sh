#!/usr/bin/zsh

# Script to download and set up local C++ libraries (raylib, imgui, rlImGui)
# for a project generated by the Neovim CppProject plugin.

# --- Configuration ---
RAYLIB_REPO="https://github.com/raysan5/raylib.git"
IMGUI_REPO="https://github.com/ocornut/imgui.git"
RLIMGUI_REPO="https://github.com/raylib-extras/rlImGui.git"
# For ImGui, you might want to specify a particular tag or branch for stability,
# e.g., IMGUI_BRANCH="-b docking" or IMGUI_BRANCH="-b v1.90.8" (replace with actual tag)
IMGUI_BRANCH="" # Empty means default branch

# --- Helper Functions ---
print_success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

print_info() {
  echo -e "\033[0;34m[INFO]\033[0m $1"
}

# --- Main Logic ---

# Check if git is installed
if ! command -v git &>/dev/null; then
  print_error "git could not be found. Please install git to use this script."
  exit 1
fi

# Check for project path argument
if [ -z "$1" ]; then
  print_error "Usage: $0 <path_to_your_project>"
  print_info "Example: $0 ./MyRaylibGame"
  exit 1
fi

PROJECT_PATH="$1"
LIBS_DIR="$PROJECT_PATH/libs"

# Check if the project path exists
if [ ! -d "$PROJECT_PATH" ]; then
  print_error "Project path '$PROJECT_PATH' does not exist."
  exit 1
fi

# Check if the libs directory exists (the Lua script should have created it)
if [ ! -d "$LIBS_DIR" ]; then
  print_info "'$LIBS_DIR' does not exist. Creating it now..."
  mkdir -p "$LIBS_DIR"
  if [ $? -ne 0 ]; then
    print_error "Failed to create '$LIBS_DIR'."
    exit 1
  fi
fi

# --- Clone Raylib ---
RAYLIB_TARGET_DIR="$LIBS_DIR/raylib"
if [ -d "$RAYLIB_TARGET_DIR/.git" ]; then
  print_info "Raylib already cloned in '$RAYLIB_TARGET_DIR'. Skipping."
else
  print_info "Cloning Raylib into '$RAYLIB_TARGET_DIR'..."
  if git clone --depth 1 "$RAYLIB_REPO" "$RAYLIB_TARGET_DIR"; then
    print_success "Raylib cloned successfully."
  else
    print_error "Failed to clone Raylib."
  fi
fi
echo # Newline for readability

# --- Clone Dear ImGui ---
IMGUI_TARGET_DIR="$LIBS_DIR/imgui"
if [ -d "$IMGUI_TARGET_DIR/.git" ]; then
  print_info "Dear ImGui already cloned in '$IMGUI_TARGET_DIR'. Skipping."
else
  print_info "Cloning Dear ImGui into '$IMGUI_TARGET_DIR'..."
  # shellcheck disable=SC2086 # We want word splitting for $IMGUI_BRANCH if it's set
  if git clone --depth 1 $IMGUI_BRANCH "$IMGUI_REPO" "$IMGUI_TARGET_DIR"; then
    print_success "Dear ImGui cloned successfully."
  else
    print_error "Failed to clone Dear ImGui."
  fi
fi
echo

# --- Clone rlImGui ---
RLIMGUI_TARGET_DIR="$LIBS_DIR/rlimgui"
if [ -d "$RLIMGUI_TARGET_DIR/.git" ]; then
  print_info "rlImGui already cloned in '$RLIMGUI_TARGET_DIR'. Skipping."
else
  print_info "Cloning rlImGui into '$RLIMGUI_TARGET_DIR'..."
  if git clone --depth 1 "$RLIMGUI_REPO" "$RLIMGUI_TARGET_DIR"; then
    print_success "rlImGui cloned successfully."
  else
    print_error "Failed to clone rlImGui."
  fi
fi
echo

print_info "Library initialization process complete for project: $PROJECT_PATH"
print_info "You should now be able to configure and build your project using CMake."
