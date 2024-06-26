### Enabling SSL Support

The Dockerfile does the heavy lifting in preparing the postgres instance to support SSL:

1. It generates a server private key and server certificate.
2. It updates the permission of the private key to disallow any access to a world or group.
3. It changes the ownership of the file to `postgres` to ensure that the file can be read.
4. Finally, it copies a script to the `/usr/local/bin` directory. This script updates the relevant SSL properties in 
`$PGDATA/postgresql.conf` file to enable SSL support.

These requirements are specified in the Postgres docs ([link here](https://www.postgresql.org/docs/current/ssl-tcp.html)).

Note that this script must be run after the Postgres instance is ready. I tried to update it within the Dockerfile,
but that results in no changes to the `$PGDATA/postgresql.conf` file. Simply run the following command after
the logs indicate the Postgres server is ready:

```bash
docker exec -it grouphq-postgres bash /usr/local/bin/init-ssl.sh
```

You can verify the SSL properties have been enabled by reading the `$PGDATA/postgresql.conf` file:

```bash
cat $PGDATA/postgresql.conf
```

One more thing. Non-SSL connections will still be accepted. To ensure that you're communicating over SSL,
make sure to pass the relevant JDBC properties for requiring SSL. For example:

`jdbc:postgresql://grouphq-postgres/grouphq_groups?ssl=true&sslMode=verify-full`
