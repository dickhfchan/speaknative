# PostgreSQL Connection Testing

This directory contains Python scripts to test PostgreSQL connection strings that are compatible with the Swift `DatabaseConnectivityTester`.

## Files

- `test_postgres_connection.py` - Main test script
- `example_postgres_tests.py` - Example usage patterns
- `requirements_python.txt` - Python dependencies
- `README_postgres_testing.md` - This documentation

## Quick Start

1. **Install dependencies:**
   ```bash
   pip3 install -r requirements_python.txt
   ```

2. **Test with environment variables:**
   ```bash
   # Option 1: Using POSTGRES_URL
   export POSTGRES_URL="postgresql://username:password@host:5432/database"
   python3 test_postgres_connection.py
   
   # Option 2: Using individual parameters
   export POSTGRES_HOST=your-host.com
   export POSTGRES_PORT=5432
   export POSTGRES_DB=your_database
   export POSTGRES_USER=your_username
   export POSTGRES_PASSWORD=your_password
   export POSTGRES_SSL_MODE=prefer
   python3 test_postgres_connection.py
   ```

## Connection String Formats

The Swift `DatabaseConnectivityTester` supports these PostgreSQL URL formats:

```
postgresql://user:password@host:port/database
postgresql://user:password@host:port/database?sslmode=require
postgresql://user:password@host:port/database?sslmode=disable
postgres://user:password@host:port/database
```

### Parameters

- **host** (required): PostgreSQL server hostname or IP address
- **port** (optional): Server port (default: 5432)
- **database** (required): Database name
- **user** (required): Username
- **password** (optional): Password
- **sslmode** (optional): SSL mode (`prefer`, `require`, `disable`, `allow`)

## Environment Variables

The test script supports these environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_URL` | Complete connection string | `postgresql://user:pass@host:5432/db` |
| `POSTGRES_HOST` | Server hostname | `localhost` |
| `POSTGRES_PORT` | Server port | `5432` |
| `POSTGRES_DB` | Database name | `mydatabase` |
| `POSTGRES_USER` | Username | `myuser` |
| `POSTGRES_PASSWORD` | Password | `mypassword` |
| `POSTGRES_SSL_MODE` | SSL mode | `prefer` |

## Test Features

The test script performs:

1. **URL Parsing**: Validates and parses PostgreSQL connection strings
2. **Connection Testing**: Attempts to connect to the database
3. **Authentication**: Verifies username/password
4. **Database Info**: Retrieves database version and metadata
5. **Table Listing**: Lists available tables (like the Swift version)
6. **Performance**: Measures connection time
7. **Error Handling**: Provides detailed error messages

## Example Output

```
🚀 PostgreSQL Connection Tester
==================================================
📋 Found POSTGRES_URL: postgresql://user:***@localhost:5432/mydb

🧪 Testing Connection...
------------------------------
🔌 Attempting connection to localhost:5432/mydb as user
   SSL Mode: prefer
✅ Connection successful

📊 Connection Details:
   Database: mydb
   User: user
   Server: 127.0.0.1:5432
   Connection Time: 45.23ms
   Active Connections: 3

🗄️  Database Info:
   PostgreSQL Version: PostgreSQL 15.4 on x86_64-pc-linux-gnu
   Tables Found: 5
   Sample Tables:
     • users
     • products
     • orders
     • categories
     • sessions

🎉 All tests passed!
```

## Troubleshooting

### Common Issues

1. **Connection Refused**
   ```
   ❌ Could not connect to server - check host/port
   ```
   - Ensure PostgreSQL server is running
   - Check hostname and port
   - Verify firewall settings

2. **Authentication Failed**
   ```
   ❌ Authentication failed - check username/password
   ```
   - Verify username and password
   - Check user permissions
   - Ensure user exists in PostgreSQL

3. **Database Does Not Exist**
   ```
   ❌ Database does not exist
   ```
   - Create the database: `CREATE DATABASE your_database;`
   - Check database name spelling
   - Verify user has access to the database

4. **SSL Issues**
   ```
   ❌ SSL connection error
   ```
   - Try `sslmode=disable` for testing
   - Check SSL certificate configuration
   - Use `sslmode=prefer` for flexible SSL

### Testing Without a PostgreSQL Server

If you don't have a PostgreSQL server running, the script will show connection errors but still validate URL formats:

```bash
python3 test_postgres_connection.py
```

This will show:
- ✅ URL format validation
- ❌ Connection errors (expected without server)

## Integration with Swift App

This Python test script validates the same connection string formats that the Swift `DatabaseConnectivityTester` uses. Use it to:

1. Test connection strings before deploying to iOS
2. Debug connection issues
3. Validate environment variable configurations
4. Test different SSL modes and connection parameters

The Swift code expects the same environment variables (`POSTGRES_URL` or individual `POSTGRES_*` variables) and uses the same URL parsing logic.
