# Use the official PostgreSQL image from the Docker hub
FROM postgres:14.4
WORKDIR /var/lib/postgresql

# Generate SSL certificates
RUN openssl genrsa -out server.key 2048 \
    && openssl req -new -x509 -days 365 -key server.key -out server.crt -subj "/C=US/ST=New York/L=Brooklyn/O=GroupHQ/OU=staging/CN=localhost" \
    && chmod 600 server.key \
    && chown postgres:postgres server.key server.crt

# Copy the initialization script
COPY init-ssl.sh /usr/local/bin
RUN chmod +x /usr/local/bin/init-ssl.sh