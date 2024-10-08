#!/bin/bash
set -e

echo "Using sed to update ssl configurations to on"

# Configure SSL more robustly
sed -ri "s/#\s*ssl\s*=\s*off/ssl = on/" $PGDATA/postgresql.conf
sed -ri "s/#\s*ssl_cert_file\s*=.*/ssl_cert_file = '\/var\/lib\/postgresql\/server.crt'/" $PGDATA/postgresql.conf
sed -ri "s/#\s*ssl_key_file\s*=.*/ssl_key_file = '\/var\/lib\/postgresql\/server.key'/" $PGDATA/postgresql.conf

echo "Finished using sed to update ssl configurations to on"

echo "Refreshing configuration"

# Refresh configuration as the postgres user (not allowed as root)
su -c "pg_ctl reload" postgres

echo "Completed configuration refresh. Check previous logs for issues"