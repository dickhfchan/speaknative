#!/usr/bin/env python3
"""
PostgreSQL Connection Test Script

This script tests PostgreSQL connection strings in various formats
to ensure compatibility with the Swift DatabaseConnectivityTester.

Usage:
    python3 test_postgres_connection.py

Environment Variables:
    POSTGRES_URL - The PostgreSQL connection string to test
    POSTGRES_HOST - Alternative: hostname (default: localhost)
    POSTGRES_PORT - Alternative: port (default: 5432)
    POSTGRES_DB - Alternative: database name (default: postgres)
    POSTGRES_USER - Alternative: username (default: postgres)
    POSTGRES_PASSWORD - Alternative: password (default: empty)
    POSTGRES_SSL_MODE - Alternative: SSL mode (default: prefer)

Examples:
    export POSTGRES_URL="postgresql://user:password@localhost:5432/dbname"
    python3 test_postgres_connection.py
    
    # Or use individual parameters
    export POSTGRES_HOST=localhost
    export POSTGRES_PORT=5432
    export POSTGRES_DB=testdb
    export POSTGRES_USER=testuser
    export POSTGRES_PASSWORD=testpass
    python3 test_postgres_connection.py
"""

import os
import sys
import urllib.parse
import psycopg2
from psycopg2 import sql
import ssl
from typing import Dict, Optional, Tuple, List
import time

class PostgreSQLConnectionTester:
    """Test PostgreSQL connection strings and configurations."""
    
    def __init__(self):
        self.connection_params = {}
        self.test_results = []
    
    def load_environment_config(self) -> Dict[str, str]:
        """Load configuration from environment variables."""
        config = {}
        
        # Try to get POSTGRES_URL first from environment
        postgres_url = os.getenv('POSTGRES_URL')
        if postgres_url:
            config['url'] = postgres_url
            print(f"📋 Found POSTGRES_URL from environment: {self._mask_password(postgres_url)}")
            return config
        
        # Try to load from .env file (similar to Swift code)
        try:
            env_path = '.env'
            if os.path.exists(env_path):
                print(f"📋 Loading configuration from .env file...")
                with open(env_path, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if not line or line.startswith('#'):
                            continue
                        if '=' in line:
                            key, value = line.split('=', 1)
                            key = key.strip()
                            value = value.strip()
                            if key == 'POSTGRES_URL' and value:
                                config['url'] = value
                                print(f"📋 Found POSTGRES_URL from .env: {self._mask_password(value)}")
                                return config
        except Exception as e:
            print(f"⚠️  Could not read .env file: {e}")
        
        # Fall back to individual parameters
        config['host'] = os.getenv('POSTGRES_HOST', 'localhost')
        config['port'] = os.getenv('POSTGRES_PORT', '5432')
        config['database'] = os.getenv('POSTGRES_DB', 'postgres')
        config['user'] = os.getenv('POSTGRES_USER', 'postgres')
        config['password'] = os.getenv('POSTGRES_PASSWORD', '')
        config['sslmode'] = os.getenv('POSTGRES_SSL_MODE', 'prefer')
        
        print("📋 Using individual environment variables:")
        for key, value in config.items():
            if key == 'password':
                print(f"  {key}: {'*' * len(value) if value else '(empty)'}")
            else:
                print(f"  {key}: {value}")
        
        return config
    
    def parse_postgres_url(self, url: str) -> Dict[str, str]:
        """Parse PostgreSQL URL into connection parameters."""
        try:
            parsed = urllib.parse.urlparse(url)
            
            if not parsed.scheme.startswith('postgres'):
                raise ValueError(f"Unsupported scheme: {parsed.scheme}")
            
            if not parsed.hostname:
                raise ValueError("Missing hostname in URL")
            
            if not parsed.username:
                raise ValueError("Missing username in URL")
            
            # Extract database name from path
            database = parsed.path.lstrip('/')
            if not database:
                raise ValueError("Missing database name in URL")
            
            # Parse query parameters for SSL mode
            query_params = urllib.parse.parse_qs(parsed.query)
            sslmode = 'prefer'  # default
            if 'sslmode' in query_params:
                sslmode = query_params['sslmode'][0].lower()
            
            config = {
                'host': parsed.hostname,
                'port': str(parsed.port or 5432),
                'database': database,
                'user': parsed.username,
                'password': parsed.password or '',
                'sslmode': sslmode
            }
            
            return config
            
        except Exception as e:
            raise ValueError(f"Invalid PostgreSQL URL: {e}")
    
    def _mask_password(self, url: str) -> str:
        """Mask password in connection string for logging."""
        try:
            parsed = urllib.parse.urlparse(url)
            if parsed.password:
                # Replace password with asterisks
                masked = url.replace(f":{parsed.password}@", ":***@")
                return masked
        except:
            pass
        return url
    
    def test_connection(self, config: Dict[str, str]) -> Tuple[bool, str, Optional[Dict]]:
        """Test PostgreSQL connection with given configuration."""
        start_time = time.time()
        
        try:
            # Convert port to integer
            port = int(config['port'])
            
            # Prepare connection parameters
            conn_params = {
                'host': config['host'],
                'port': port,
                'database': config['database'],
                'user': config['user'],
                'password': config['password'],
            }
            
            # Handle SSL mode
            sslmode = config.get('sslmode', 'prefer').lower()
            if sslmode in ['disable', 'allow']:
                conn_params['sslmode'] = 'disable'
            elif sslmode == 'require':
                conn_params['sslmode'] = 'require'
            else:  # prefer, allow, etc.
                conn_params['sslmode'] = 'prefer'
            
            print(f"🔌 Attempting connection to {config['host']}:{port}/{config['database']} as {config['user']}")
            print(f"   SSL Mode: {sslmode}")
            
            # Attempt connection
            conn = psycopg2.connect(**conn_params)
            
            # Test basic connectivity
            cursor = conn.cursor()
            cursor.execute("SELECT version();")
            version = cursor.fetchone()[0]
            
            # Get database info
            cursor.execute("""
                SELECT 
                    current_database() as database_name,
                    current_user as current_user,
                    inet_server_addr() as server_addr,
                    inet_server_port() as server_port
            """)
            db_info = cursor.fetchone()
            
            # Get table information (similar to Swift code)
            cursor.execute("""
                SELECT table_schema, table_name
                FROM information_schema.tables
                WHERE table_type = 'BASE TABLE'
                ORDER BY table_schema, table_name
                LIMIT 10
            """)
            tables = cursor.fetchall()
            
            # Get connection stats
            cursor.execute("SELECT count(*) FROM pg_stat_activity WHERE state = 'active';")
            active_connections = cursor.fetchone()[0]
            
            cursor.close()
            conn.close()
            
            connection_time = time.time() - start_time
            
            result_info = {
                'version': version,
                'database_name': db_info[0],
                'current_user': db_info[1],
                'server_addr': db_info[2],
                'server_port': db_info[3],
                'table_count': len(tables),
                'tables': [f"{schema}.{table}" if schema != 'public' else table 
                          for schema, table in tables],
                'active_connections': active_connections,
                'connection_time_ms': round(connection_time * 1000, 2)
            }
            
            return True, "Connection successful", result_info
            
        except psycopg2.OperationalError as e:
            error_msg = str(e)
            if "authentication failed" in error_msg.lower():
                return False, "Authentication failed - check username/password", None
            elif "does not exist" in error_msg.lower():
                return False, "Database does not exist", None
            elif "could not connect to server" in error_msg.lower():
                return False, "Could not connect to server - check host/port", None
            else:
                return False, f"Connection error: {error_msg}", None
                
        except psycopg2.ProgrammingError as e:
            return False, f"Programming error: {e}", None
            
        except Exception as e:
            return False, f"Unexpected error: {e}", None
    
    def run_comprehensive_tests(self):
        """Run comprehensive connection tests."""
        print("🚀 PostgreSQL Connection Tester")
        print("=" * 50)
        
        # Load configuration
        try:
            env_config = self.load_environment_config()
        except Exception as e:
            print(f"❌ Configuration error: {e}")
            return False
        
        # Parse configuration
        if 'url' in env_config:
            try:
                config = self.parse_postgres_url(env_config['url'])
                print(f"✅ Successfully parsed POSTGRES_URL")
            except Exception as e:
                print(f"❌ Failed to parse POSTGRES_URL: {e}")
                return False
        else:
            config = env_config
        
        print("\n🧪 Testing Connection...")
        print("-" * 30)
        
        # Test connection
        success, message, info = self.test_connection(config)
        
        if success:
            print(f"✅ {message}")
            print(f"\n📊 Connection Details:")
            print(f"   Database: {info['database_name']}")
            print(f"   User: {info['current_user']}")
            print(f"   Server: {info['server_addr']}:{info['server_port']}")
            print(f"   Connection Time: {info['connection_time_ms']}ms")
            print(f"   Active Connections: {info['active_connections']}")
            print(f"\n🗄️  Database Info:")
            print(f"   PostgreSQL Version: {info['version']}")
            print(f"   Tables Found: {info['table_count']}")
            
            if info['tables']:
                print("   Sample Tables:")
                for table in info['tables'][:5]:  # Show first 5 tables
                    print(f"     • {table}")
                if len(info['tables']) > 5:
                    print(f"     ... and {len(info['tables']) - 5} more")
            else:
                print("   No tables found in database")
            
            return True
        else:
            print(f"❌ {message}")
            return False
    
    def test_url_formats(self):
        """Test various URL formats for compatibility."""
        print("\n🔬 Testing URL Format Compatibility")
        print("-" * 40)
        
        test_urls = [
            "postgresql://user:pass@localhost:5432/dbname",
            "postgres://user:pass@localhost:5432/dbname",
            "postgresql://user:pass@localhost/dbname",  # default port
            "postgresql://user@localhost:5432/dbname",  # no password
            "postgresql://user:pass@localhost:5432/dbname?sslmode=require",
            "postgresql://user:pass@localhost:5432/dbname?sslmode=disable",
        ]
        
        for url in test_urls:
            try:
                config = self.parse_postgres_url(url)
                print(f"✅ {self._mask_password(url)}")
                print(f"   → host={config['host']}, port={config['port']}, "
                      f"db={config['database']}, user={config['user']}, "
                      f"ssl={config['sslmode']}")
            except Exception as e:
                print(f"❌ {self._mask_password(url)}")
                print(f"   → Error: {e}")
            print()

def check_dependencies():
    """Check if required dependencies are installed."""
    try:
        import psycopg2
        print("✅ psycopg2 is installed")
        return True
    except ImportError:
        print("❌ psycopg2 is not installed")
        print("   Install with: pip install psycopg2-binary")
        return False

def main():
    """Main function."""
    print("PostgreSQL Connection Test Script")
    print("=" * 50)
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Run tests
    tester = PostgreSQLConnectionTester()
    
    # Test URL format compatibility
    tester.test_url_formats()
    
    # Run comprehensive connection test
    success = tester.run_comprehensive_tests()
    
    if success:
        print(f"\n🎉 All tests passed!")
        sys.exit(0)
    else:
        print(f"\n💥 Tests failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
