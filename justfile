# cuti development automation

# Increment patch version (bugfix), build, publish, and update local tool
publish:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "⚠️  Uncommitted changes detected!"
        git status --short
        echo ""
        read -p "Do you want to continue with publishing? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Publishing cancelled"
            exit 1
        fi
    else
        echo "✅ No uncommitted changes"
    fi
    
    echo "🔢 Incrementing patch version..."
    # Read current version
    current_version=$(grep '^version = ' pyproject.toml | cut -d'"' -f2)
    echo "Current version: $current_version"
    
    # Split version into parts
    IFS='.' read -r major minor patch <<< "$current_version"
    
    # Increment patch version
    new_patch=$((patch + 1))
    new_version="$major.$minor.$new_patch"
    
    echo "New version: $new_version"
    
    # Update pyproject.toml
    sed -i '' "s/^version = \".*\"/version = \"$new_version\"/" pyproject.toml
    
    echo "✅ Updated pyproject.toml to version $new_version"
    
    echo "🔄 Running uv sync..."
    uv sync
    
    echo "🧹 Cleaning old build artifacts..."
    rm -rf dist/
    
    echo "🏗️  Building package..."
    uv build
    
    echo "📦 Publishing to PyPI..."
    uv publish
    
    echo "🔧 Updating local tool installation..."
    # Loop until the tool is updated with the new version
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt: Updating cuti tool..."
        
        # Update the tool (will install if not present)
        uv tool update cuti
        
        # Check if the installed version matches the new version
        installed_version=$(uv tool run cuti version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        
        if [ "$installed_version" = "$new_version" ]; then
            echo "✅ Tool successfully updated to version $new_version"
            break
        else
            echo "⏳ Tool version is $installed_version, waiting for PyPI propagation... (attempt $attempt/$max_attempts)"
            sleep 10
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "❌ Failed to update tool after $max_attempts attempts"
        echo "The package was published but tool installation timed out"
        echo "Try running 'uv tool install cuti' manually in a few minutes"
        exit 1
    fi
    
    echo "🎉 Successfully published and installed cuti version $new_version"

# Increment minor version (feature release), build, publish, and update local tool
publish-minor:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "⚠️  Uncommitted changes detected!"
        git status --short
        echo ""
        read -p "Do you want to continue with publishing? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Publishing cancelled"
            exit 1
        fi
    else
        echo "✅ No uncommitted changes"
    fi
    
    echo "🔢 Incrementing minor version..."
    # Read current version
    current_version=$(grep '^version = ' pyproject.toml | cut -d'"' -f2)
    echo "Current version: $current_version"
    
    # Split version into parts
    IFS='.' read -r major minor patch <<< "$current_version"
    
    # Increment minor version, reset patch to 0
    new_minor=$((minor + 1))
    new_version="$major.$new_minor.0"
    
    echo "New version: $new_version"
    
    # Update pyproject.toml
    sed -i '' "s/^version = \".*\"/version = \"$new_version\"/" pyproject.toml
    
    echo "✅ Updated pyproject.toml to version $new_version"
    
    echo "🔄 Running uv sync..."
    uv sync
    
    echo "🧹 Cleaning old build artifacts..."
    rm -rf dist/
    
    echo "🏗️  Building package..."
    uv build
    
    echo "📦 Publishing to PyPI..."
    uv publish
    
    echo "🔧 Updating local tool installation..."
    # Loop until the tool is updated with the new version
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt: Updating cuti tool..."
        
        # Update the tool (will install if not present)
        uv tool update cuti
        
        # Check if the installed version matches the new version
        installed_version=$(uv tool run cuti version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        
        if [ "$installed_version" = "$new_version" ]; then
            echo "✅ Tool successfully updated to version $new_version"
            break
        else
            echo "⏳ Tool version is $installed_version, waiting for PyPI propagation... (attempt $attempt/$max_attempts)"
            sleep 10
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "❌ Failed to update tool after $max_attempts attempts"
        echo "The package was published but tool installation timed out"
        echo "Try running 'uv tool install cuti' manually in a few minutes"
        exit 1
    fi
    
    echo "🎉 Successfully published and installed cuti version $new_version"

# Just build without publishing
build:
    echo "🏗️  Building package..."
    uv build

# Install development version locally
install-dev:
    echo "🔧 Installing development version..."
    uv pip install -e . --force-reinstall

# Show current version
version:
    #!/usr/bin/env bash
    current_version=$(grep '^version = ' pyproject.toml | cut -d'"' -f2)
    echo "pyproject.toml version: $current_version"
    
    if command -v cuti >/dev/null 2>&1; then
        echo "Installed cuti version: $(cuti version)"
    else
        echo "cuti not found in PATH"
    fi
    
    if uv tool list | grep -q cuti; then
        echo "Tool cuti version: $(uv tool run cuti version 2>/dev/null || echo 'failed to get version')"
    else
        echo "cuti tool not installed"
    fi

# Clean build artifacts
clean:
    echo "🧹 Cleaning build artifacts..."
    rm -rf dist/
    rm -rf build/
    rm -rf *.egg-info/

# Help
help:
    just --list