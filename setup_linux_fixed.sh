#!/bin/bash

echo "Setting up Deribit Trading System on Ubuntu/Debian..."

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Function to install packages with fallback options
install_package_with_fallback() {
    local package_name=$1
    shift
    local fallback_packages=("$@")
    
    echo "Attempting to install $package_name..."
    if sudo apt install -y "$package_name" 2>/dev/null; then
        echo "Successfully installed $package_name"
        return 0
    else
        echo "Package $package_name not found, trying alternatives..."
        for fallback in "${fallback_packages[@]}"; do
            echo "Trying $fallback..."
            if sudo apt install -y "$fallback" 2>/dev/null; then
                echo "Successfully installed $fallback"
                return 0
            fi
        done
        echo "Warning: Could not install $package_name or any alternatives"
        return 1
    fi
}

# Install basic dependencies
echo "Installing basic dependencies..."
sudo apt install -y cmake gcc g++ libssl-dev git libreadline-dev

# Try to install Boost packages with fallbacks
echo "Installing Boost libraries..."
install_package_with_fallback "libboost-all-dev" "libboost-system-dev" "libboost-thread-dev" "libboost-dev"

# Try to install nlohmann-json with fallbacks (optional since project includes it)
echo "Installing nlohmann-json (optional)..."
install_package_with_fallback "nlohmann-json3-dev" "nlohmann-json-dev" "libnlohmann-json3-dev"

# Check if we have the minimum required packages
echo "Checking installed packages..."
if ! dpkg -l | grep -q "libboost"; then
    echo "Error: No Boost libraries found. Please install manually:"
    echo "sudo apt install libboost-system-dev libboost-thread-dev"
    exit 1
fi

# Build the project
echo "Building the project..."
mkdir -p build && cd build

# Configure with CMake
echo "Configuring with CMake..."
if cmake .. -Wno-dev; then
    echo "CMake configuration successful"
else
    echo "CMake configuration failed. Trying without warnings..."
    cmake ..
fi

# Build the project
echo "Building the project..."
if cmake --build .; then
    echo "Build successful!"
else
    echo "Build failed. Trying with verbose output..."
    cmake --build . --verbose
fi

# Check if executable was created
if [ -f "./deribit_trader" ]; then
    echo "Setup complete! You can now run './deribit_trader' to start the application."
    echo "Starting the application..."
    ./deribit_trader
else
    echo "Error: Executable not found. Build may have failed."
    echo "Check the build output above for errors."
    exit 1
fi
