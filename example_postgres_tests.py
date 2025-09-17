#!/usr/bin/env python3
"""
Example PostgreSQL Connection Tests

This script demonstrates how to test various PostgreSQL connection configurations
that would be compatible with the Swift DatabaseConnectivityTester.

Usage Examples:
    # Test with environment variable
    export POSTGRES_URL="postgresql://user:password@host:5432/database"
    python3 test_postgres_connection.py
    
    # Test with individual parameters
    export POSTGRES_HOST=your-host.com
    export POSTGRES_PORT=5432
    export POSTGRES_DB=your_database
    export POSTGRES_USER=your_username
    export POSTGRES_PASSWORD=your_password
    python3 test_postgres_connection.py
    
    # Test with SSL disabled
    export POSTGRES_URL="postgresql://user:password@host:5432/database?sslmode=disable"
    python3 test_postgres_connection.py
"""

import os
import subprocess
import sys

def run_test_with_env(env_vars):
    """Run the test script with specific environment variables."""
    print(f"\n🧪 Testing with environment variables:")
    for key, value in env_vars.items():
        if 'password' in key.lower():
            print(f"  {key}=***")
        else:
            print(f"  {key}={value}")
    
    # Set environment variables
    env = os.environ.copy()
    env.update(env_vars)
    
    # Run the test script
    result = subprocess.run([sys.executable, 'test_postgres_connection.py'], 
                          env=env, capture_output=True, text=True)
    
    print("\n📋 Test Output:")
    print(result.stdout)
    if result.stderr:
        print("❌ Errors:")
        print(result.stderr)
    
    return result.returncode == 0

def main():
    """Run example tests with different configurations."""
    print("PostgreSQL Connection Test Examples")
    print("=" * 50)
    
    # Example 1: Local PostgreSQL (will fail if not running)
    print("\n📝 Example 1: Local PostgreSQL (default settings)")
    success = run_test_with_env({
        'POSTGRES_HOST': 'localhost',
        'POSTGRES_PORT': '5432',
        'POSTGRES_DB': 'postgres',
        'POSTGRES_USER': 'postgres',
        'POSTGRES_PASSWORD': '',
        'POSTGRES_SSL_MODE': 'prefer'
    })
    
    # Example 2: Using POSTGRES_URL format
    print("\n📝 Example 2: Using POSTGRES_URL format")
    success = run_test_with_env({
        'POSTGRES_URL': 'postgresql://postgres@localhost:5432/postgres?sslmode=prefer'
    })
    
    # Example 3: SSL disabled
    print("\n📝 Example 3: SSL disabled")
    success = run_test_with_env({
        'POSTGRES_URL': 'postgresql://postgres@localhost:5432/postgres?sslmode=disable'
    })
    
    # Example 4: Remote server (example - will fail without real server)
    print("\n📝 Example 4: Remote server example")
    success = run_test_with_env({
        'POSTGRES_URL': 'postgresql://username:password@your-server.com:5432/your_database?sslmode=require'
    })
    
    print("\n💡 Tips:")
    print("  1. Make sure PostgreSQL server is running and accessible")
    print("  2. Check firewall settings if connecting to remote servers")
    print("  3. Verify username/password credentials")
    print("  4. Ensure the database exists")
    print("  5. Check SSL/TLS settings if required")
    
    print("\n📚 Common PostgreSQL connection string formats:")
    print("  postgresql://user:password@host:port/database")
    print("  postgresql://user:password@host:port/database?sslmode=require")
    print("  postgresql://user:password@host:port/database?sslmode=disable")
    print("  postgres://user:password@host:port/database")
    
    print("\n🔧 To test with your own PostgreSQL server:")
    print("  1. Set the POSTGRES_URL environment variable")
    print("  2. Or set individual POSTGRES_* environment variables")
    print("  3. Run: python3 test_postgres_connection.py")

if __name__ == "__main__":
    main()
