#!/bin/bash
# PostgreSQL Connection Test Script
# 
# This script provides convenient commands to test PostgreSQL connections
# that are compatible with the Swift DatabaseConnectivityTester.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if Python dependencies are installed
check_dependencies() {
    print_status "Checking Python dependencies..."
    
    if ! python3 -c "import psycopg2" 2>/dev/null; then
        print_warning "psycopg2 not found. Installing..."
        pip3 install psycopg2-binary
        print_success "psycopg2 installed successfully"
    else
        print_success "psycopg2 is available"
    fi
}

# Function to run the test
run_test() {
    print_status "Running PostgreSQL connection test..."
    python3 test_postgres_connection.py
}

# Function to show help
show_help() {
    echo "PostgreSQL Connection Test Helper"
    echo "================================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  test        Run the connection test (default)"
    echo "  examples    Run example tests with different configurations"
    echo "  install     Install Python dependencies"
    echo "  help        Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  POSTGRES_URL        Complete connection string"
    echo "  POSTGRES_HOST       Server hostname (default: localhost)"
    echo "  POSTGRES_PORT       Server port (default: 5432)"
    echo "  POSTGRES_DB         Database name (default: postgres)"
    echo "  POSTGRES_USER       Username (default: postgres)"
    echo "  POSTGRES_PASSWORD   Password (default: empty)"
    echo "  POSTGRES_SSL_MODE   SSL mode (default: prefer)"
    echo ""
    echo "Examples:"
    echo "  # Test with URL"
    echo "  export POSTGRES_URL='postgresql://user:pass@host:5432/db'"
    echo "  $0 test"
    echo ""
    echo "  # Test with individual parameters"
    echo "  export POSTGRES_HOST=localhost"
    echo "  export POSTGRES_DB=mydb"
    echo "  export POSTGRES_USER=myuser"
    echo "  export POSTGRES_PASSWORD=mypass"
    echo "  $0 test"
    echo ""
    echo "  # Run examples"
    echo "  $0 examples"
}

# Function to run examples
run_examples() {
    print_status "Running PostgreSQL connection examples..."
    python3 example_postgres_tests.py
}

# Function to install dependencies
install_deps() {
    print_status "Installing Python dependencies..."
    pip3 install -r requirements_python.txt
    print_success "Dependencies installed successfully"
}

# Main script logic
case "${1:-test}" in
    "test")
        check_dependencies
        run_test
        ;;
    "examples")
        check_dependencies
        run_examples
        ;;
    "install")
        install_deps
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
