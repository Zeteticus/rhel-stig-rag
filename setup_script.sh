#!/bin/bash

# RHEL STIG RAG System Setup Script
# This script helps set up the RHEL STIG RAG system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  RHEL STIG RAG System Setup   ${NC}"
    echo -e "${BLUE}    (RHEL 9 Primary Focus)     ${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_status "Python 3 found: ${PYTHON_VERSION}"
    else
        print_error "Python 3 not found. Please install Python 3.8 or later."
        exit 1
    fi
}

create_venv() {
    print_status "Creating virtual environment..."
    python3 -m venv stig_rag_env
    source stig_rag_env/bin/activate
    print_status "Virtual environment created and activated"
}

install_requirements() {
    print_status "Installing requirements..."
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
    print_status "Requirements installed successfully"
}

setup_directories() {
    print_status "Creating necessary directories..."
    mkdir -p stig_data
    mkdir -p stig_chroma_db
    mkdir -p logs
    print_status "Directories created"
}

download_sample_data() {
    print_status "Setting up sample STIG data..."
    python3 stig_data_collector.py --create-sample-only
    print_status "Sample data created"
}

start_application() {
    print_status "Starting RHEL STIG RAG application..."
    python3 rhel_stig_rag.py &
    APP_PID=$!
    
    # Wait for the application to start
    sleep 5
    
    # Check if application is running
    if kill -0 $APP_PID 2>/dev/null; then
        print_status "Application started successfully (PID: $APP_PID)"
        echo $APP_PID > .app_pid
    else
        print_error "Failed to start application"
        exit 1
    fi
}

test_installation() {
    print_status "Testing installation..."
    
    # Test health endpoint
    if curl -s http://localhost:8000/health > /dev/null; then
        print_status "Health check passed"
    else
        print_warning "Health check failed - application may still be starting"
    fi
    
    # Load sample data
    print_status "Loading sample STIG data (RHEL 9 first, then RHEL 8)..."
    RHEL9_FILE=$(pwd)/stig_data/sample_rhel9_stig.json
    RHEL8_FILE=$(pwd)/stig_data/sample_rhel8_stig.json
    
    # Load RHEL 9 (primary)
    curl -X POST "http://localhost:8000/load-stig?file_path=${RHEL9_FILE}"
    echo
    
    # Load RHEL 8 (secondary)  
    curl -X POST "http://localhost:8000/load-stig?file_path=${RHEL8_FILE}"
    echo
    
    # Test query with RHEL 9 focus
    print_status "Testing query functionality (RHEL 9 focus)..."
    python3 stig_client.py query "How do I verify GPG signatures?" --rhel-version 9
}

show_usage() {
    print_status "Setup complete! Here's how to use the system (RHEL 9 focused):"
    echo
    echo "1. Start the server (if not already running):"
    echo "   python3 rhel_stig_rag.py"
    echo
    echo "2. Use the client to query STIG information:"
    echo "   python3 stig_client.py query 'How do I configure secure boot?'"
    echo "   python3 stig_client.py query 'How do I configure secure boot?' --rhel-version 9"
    echo "   python3 stig_client.py query 'How do I configure secure boot?' --rhel-version 8"
    echo
    echo "3. Search for specific STIG controls:"
    echo "   python3 stig_client.py search RHEL-09-211010  # RHEL 9"
    echo "   python3 stig_client.py search RHEL-08-010010  # RHEL 8"
    echo
    echo "4. Interactive mode (with version-specific commands):"
    echo "   python3 stig_client.py interactive"
    echo "   STIG> query How do I enable kernel lockdown?  # Defaults to RHEL 9"
    echo "   STIG> query9 How do I enable kernel lockdown? # RHEL 9 specific"
    echo "   STIG> query8 How do I enable kernel lockdown? # RHEL 8 specific"
    echo
    echo "5. Load additional STIG documents:"
    echo "   python3 stig_client.py load /path/to/rhel9-stig.xml"
    echo "   python3 stig_client.py load /path/to/rhel8-stig.xml"
    echo
    echo "6. Access the API documentation at: http://localhost:8000/docs"
    echo
    echo "7. Stop the server:"
    echo "   kill \$(cat .app_pid) && rm .app_pid"
}

cleanup() {
    if [ -f .app_pid ]; then
        APP_PID=$(cat .app_pid)
        print_status "Stopping application (PID: $APP_PID)..."
        kill $APP_PID 2>/dev/null || true
        rm .app_pid
    fi
}

# Main setup process
main() {
    print_header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dev)
                DEV_MODE=true
                shift
                ;;
            --no-test)
                NO_TEST=true
                shift
                ;;
            --cleanup)
                cleanup
                exit 0
                ;;
            --help)
                echo "Usage: $0 [--dev] [--no-test] [--cleanup] [--help]"
                echo "  --dev      Enable development mode"
                echo "  --no-test  Skip installation testing"
                echo "  --cleanup  Stop application and cleanup"
                echo "  --help     Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Trap to cleanup on exit
    trap cleanup EXIT
    
    # Check prerequisites
    check_python
    
    # Setup virtual environment
    if [ ! -d "stig_rag_env" ]; then
        create_venv
    else
        source stig_rag_env/bin/activate
        print_status "Using existing virtual environment"
    fi
    
    # Install requirements
    install_requirements
    
    # Setup directories
    setup_directories
    
    # Create sample data if it doesn't exist
    if [ ! -f "stig_data/sample_rhel9_stig.json" ]; then
        cat > stig_data_creator.py << 'EOF'
import json
from pathlib import Path

def create_sample_data():
    rhel9_controls = [
        {
            "id": "RHEL-09-211010",
            "title": "RHEL 9 must be configured to verify the signature of packages",
            "severity": "high",
            "version": "9",
            "description": "Changes to any software components can have significant effects on the overall security of the operating system.",
            "check": "Verify Red Hat GPG signature checking is configured with: $ sudo grep gpgcheck /etc/dnf/dnf.conf",
            "fix": "Configure Red Hat package signature checking by editing /etc/dnf/dnf.conf and ensure: gpgcheck=1",
            "references": ["CCI-001749"],
            "category": "Package Management"
        },
        {
            "id": "RHEL-09-211015",
            "title": "RHEL 9 must have the gpgcheck enabled for all repositories",
            "severity": "high", 
            "version": "9",
            "description": "Changes to any software components can have significant effects on the overall security of the operating system.",
            "check": "Verify that gpgcheck is enabled for all repositories in /etc/yum.repos.d/",
            "fix": "Edit each repository file in /etc/yum.repos.d/ and ensure gpgcheck=1",
            "references": ["CCI-001749"],
            "category": "Package Management"
        }
    ]
    
    rhel8_controls = [
        {
            "id": "RHEL-08-010010",
            "title": "RHEL 8 must be configured to verify the signature of packages",
            "severity": "high",
            "version": "8",
            "description": "Changes to any software components can have significant effects on the overall security of the operating system.",
            "check": "Verify Red Hat GPG signature checking is configured with: $ sudo grep gpgcheck /etc/yum.conf",
            "fix": "Configure Red Hat package signature checking by editing /etc/yum.conf and ensure: gpgcheck=1",
            "references": ["CCI-001749"],
            "category": "Package Management"
        }
    ]
    
    # RHEL 9 (primary)
    rhel9_data = {
        "version": "RHEL-9-STIG-V1R3",
        "release_date": "2024-01-01",
        "rhel_version": "9",
        "priority": 1,
        "controls": rhel9_controls
    }
    
    # RHEL 8 (secondary)
    rhel8_data = {
        "version": "RHEL-8-STIG-V1R12", 
        "release_date": "2023-01-01",
        "rhel_version": "8",
        "priority": 2,
        "controls": rhel8_controls
    }
    
    Path("stig_data").mkdir(exist_ok=True)
    with open("stig_data/sample_rhel9_stig.json", 'w') as f:
        json.dump(rhel9_data, f, indent=2)
    
    with open("stig_data/sample_rhel8_stig.json", 'w') as f:
        json.dump(rhel8_data, f, indent=2)
    
    print("Sample data created for both RHEL 9 and RHEL 8")

if __name__ == "__main__":
    create_sample_data()
EOF
        python3 stig_data_creator.py
        rm stig_data_creator.py
    fi
    
    # Start application in development mode
    if [ "$DEV_MODE" = true ]; then
        print_status "Starting in development mode..."
        # Start with auto-reload
        uvicorn rhel_stig_rag:app --reload --host 0.0.0.0 --port 8000 &
        APP_PID=$!
        echo $APP_PID > .app_pid
    else
        start_application
    fi
    
    # Test installation
    if [ "$NO_TEST" != true ]; then
        sleep 3  # Give the server time to start
        test_installation
    fi
    
    # Show usage instructions
    show_usage
    
    print_status "Setup completed successfully!"
}

# Run main function
main "$@"