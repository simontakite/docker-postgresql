# About absolootly/docker-postgresql

- [Introduction](#introduction)
- [Getting started](#getting-started)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
  - [Persistence](#persistence)
  - [Trusting local connections](#trusting-local-connections)
  - [Setting `postgres` user password](#setting-postgres-user-password)
  - [Creating database user](#creating-database-user)
  - [Creating databases](#creating-databases)
  - [Granting user access to a database](#granting-user-access-to-a-database)
  - [Enabling extensions](#enabling-extensions)
  - [Creating replication user](#creating-replication-user)
  - [Setting up a replication cluster](#setting-up-a-replication-cluster)
  - [Creating a snapshot](#creating-a-snapshot)
  - [Creating a backup](#creating-a-backup)
  - [Command-line arguments](#command-line-arguments)
  - [Logs](#logs)
  - [UID/GID mapping](#uid-gid-mapping)
- [Maintenance](#maintenance)
  - [Upgrading](#upgrading)
  - [Shell Access](#shell-access)

# Introduction

This docker image is derived from [absolootly](https://hub.docker.com/r/absolootly/docker-postgresql/) and remodified to install on a flattened ubuntu 15.10 image on [docker hub](https://hub.docker.com/r/absolootly/ubuntu15.10/).

PostgreSQL is an object-relational database management system (ORDBMS) with an emphasis on extensibility and standards-compliance [[source](https://en.wikipedia.org/wiki/PostgreSQL)].

# Getting started

## Installation

Automated builds of the image are available on [Dockerhub](https://hub.docker.com/r/absolootly/docker-postgresql) and is the recommended method of installation.

```bash
docker pull absolootly/docker-postgresql:latest
```

Alternatively you can build the image yourself.

```bash
docker build -t absolootly/postgresql:latest github.com/simontakite/docker-postgresql
```

## Quickstart

Start PostgreSQL using:

```bash
docker run --name postgresql -itd --restart always \
  --publish 5432:5432 \
  --volume /srv/docker/postgresql:/var/lib/postgresql \
  absolootly/docker-postgresql:latest
```

Login to the PostgreSQL server using:

```bash
docker exec -it postgresql sudo -u postgres psql
```

*Alternatively, you can use the sample [docker-compose.yml](docker-compose.yml) file to start the container using [Docker Compose](https://docs.docker.com/compose/)*

## Persistence

For PostgreSQL to preserve its state across container shutdown and startup you should mount a volume at `/var/lib/postgresql`.

> *The [Quickstart](#quickstart) command already mounts a volume for persistence.*

SELinux users should update the security context of the host mountpoint so that it plays nicely with Docker:

```bash
mkdir -p /srv/docker/postgresql
chcon -Rt svirt_sandbox_file_t /srv/docker/postgresql
```

## Trusting local connections

By default connections to the PostgreSQL server need to authenticated using a password. If desired you can trust connections from the local network using the `PG_TRUST_LOCALNET` variable.

```bash
docker run --name postgresql -itd --restart always \
  --env 'PG_TRUST_LOCALNET=true' \
  absolootly/docker-postgresql:latest
```

> **Note**
>
> The local network here is network to which the container is attached. This has different meanings depending on the `--net` parameter specified while starting the container. In the default configuration, this parameter would trust connections from other containers on the `docker0` bridge.

## Setting `postgres` user password

By default the `postgres` user is not assigned a password and as a result you can only login to the PostgreSQL server locally. If you wish to login remotely to the PostgreSQL server as the `postgres` user, you will need to assign a password for the user using the `PG_PASSWORD` variable.

```bash
docker run --name postgresql -itd --restart always \
  --env 'PG_PASSWORD=passw0rd' \
  absolootly/docker-postgresql:latest
```


> **Note**
>
> - When [persistence](#persistence) is in use, `PG_PASSWORD` is effective on the first run.
> - This feature is only available in the `latest` and versions > `9.4-10`

## Creating database user

A new PostgreSQL database user can be created by specifying the `DB_USER` and `DB_PASS` variables while starting the container.

```bash
docker run --name postgresql -itd --restart always \
  --env 'DB_USER=dbuser' --env 'DB_PASS=dbuserpass' \
  absolootly/docker-postgresql:latest
```

> **Notes**
>
> - The created user can login remotely
> - The container will error out if a password is not specified for the user
> - No changes will be made if the user already exists
> - Only a single user can be created at each launch

## Creating databases

A new PostgreSQL database can be created by specifying the `DB_NAME` variable while starting the container.

```bash
docker run --name postgresql -itd --restart always \
  --env 'DB_NAME=dbname' \
  absolootly/docker-postgresql:latest
```

By default databases are created by copying the standard system database named `template1`. You can specify a different template for your database using the `DB_TEMPLATE` parameter. Refer to [Template Databases](http://www.postgresql.org/docs/9.4/static/manage-ag-templatedbs.html) for further information.

Additionally, more than one database can be created by specifying a comma separated list of database names in `DB_NAME`. For example, the following command creates two new databases named `dbname1` and `dbname2`.

*This feature is only available in releases greater than `9.1-1`*

```bash
docker run --name postgresql -itd --restart always \
  --env 'DB_NAME=dbname1,dbname2' \
  absolootly/docker-postgresql:latest
```

## Granting user access to a database

If the `DB_USER` and `DB_PASS` variables are specified along with the `DB_NAME` variable, then the user specified in `DB_USER` will be granted access to all the databases listed in `DB_NAME`. Note that if the user and/or databases do not exist, they will be created.

```bash
docker run --name postgresql -itd --restart always \
  --env 'DB_USER=dbuser' --env 'DB_PASS=dbuserpass' \
  --env 'DB_NAME=dbname1,dbname2' \
  absolootly/docker-postgresql:latest
```

In the above example `dbuser` with be granted access to both the `dbname1` and `dbname2` databases.

# Enabling extensions

The image also packages the [postgres contrib module](http://www.postgresql.org/docs/9.4/static/contrib.html). A comma separated list of modules can be specified using the `DB_EXTENSION` parameter.

```bash
docker run --name postgresql -itd \
  --env 'DB_NAME=db1,db2' --env 'DB_EXTENSION=unaccent,pg_trgm' \
  absolootly/docker-postgresql:latest
```

The above command enables the `unaccent` and `pg_trgm` modules on the databases listed in `DB_NAME`, namely `db1` and `db2`.

> **NOTE**:
>
> This option deprecates the `DB_UNACCENT` parameter.

## Creating replication user

Similar to the creation of a database user, a new PostgreSQL replication user can be created by specifying the `REPLICATION_USER` and `REPLICATION_PASS` variables while starting the container.

```bash
docker run --name postgresql -itd --restart always \
  --env 'REPLICATION_USER=repluser' --env 'REPLICATION_PASS=repluserpass' \
  absolootly/docker-postgresql:latest
```

> **Notes**
>
> - The created user can login remotely
> - The container will error out if a password is not specified for the user
> - No changes will be made if the user already exists
> - Only a single user can be created at each launch

*It is a good idea to create a replication user even if you are not going to use it as it will allow you to setup slave nodes and/or generate snapshots and backups when the need arises.*

## Setting up a replication cluster

When the container is started, it is by default configured to act as a master node in a replication cluster. This means that you can scale your PostgreSQL database backend when the need arises without incurring any downtime. However do note that a replication user must exist on the master node for this to work.

Begin by creating the master node of our cluster:

```bash
docker run --name postgresql-master -itd --restart always \
  --env 'DB_USER=dbuser' --env 'DB_PASS=dbuserpass' --env 'DB_NAME=dbname' \
  --env 'REPLICATION_USER=repluser' --env 'REPLICATION_PASS=repluserpass' \
  absolootly/docker-postgresql:latest
```

Notice that no additional arguments are specified while starting the master node of the cluster.

To create a replication slave the `REPLICATION_MODE` variable should be set to `slave` and additionally the `REPLICATION_HOST`, `REPLICATION_PORT`, `REPLICATION_SSLMODE`, `REPLICATION_USER` and `REPLICATION_PASS` variables should be specified.

Create a slave node:

```bash
docker run --name postgresql-slave01 -itd --restart always \
  --link postgresql-master:master \
  --env 'REPLICATION_MODE=slave' --env 'REPLICATION_SSLMODE=prefer' \
  --env 'REPLICATION_HOST=master' --env 'REPLICATION_PORT=5432'  \
  --env 'REPLICATION_USER=repluser' --env 'REPLICATION_PASS=repluserpass' \
  absolootly/docker-postgresql:latest
```

*In the above command, we used docker links so that we can address the master node using the `master` alias in `REPLICATION_HOST`.*

> **Note**
>
> - The default value of `REPLICATION_PORT` is `5432`
> - The default value of `REPLICATION_SSLMODE` is `prefer`
> - The value of `REPLICATION_USER` and `REPLICATION_PASS` should be the same as the ones specified on the master node.
> - With [persistence](#persistence) in use, if the container is stopped and started, for the container continue to function as a slave you need to ensure that `REPLICATION_MODE=slave` is defined in the containers environment. In the absense of which the slave configuration will be turned off and the node will allow writing to it while having the last synced data from the master.

And just like that with minimal effort you have a PostgreSQL replication cluster setup. You can create additional slaves to scale the cluster horizontally.

Here are some important notes about a PostgreSQL replication cluster:

 - Writes can only occur on the master
 - Slaves are read-only
 - For best performance, limit the reads to the slave nodes

## Creating a snapshot

Similar to a creating replication slave node, you can create a snapshot of the master by specifying `REPLICATION_MODE=snapshot`.

Once the master node is created as specified in [Setting up a replication cluster](#setting-up-a-replication-cluster), you can create a snapshot using:

```bash
docker run --name postgresql-snapshot -itd --restart always \
  --link postgresql-master:master \
  --env 'REPLICATION_MODE=snapshot' --env 'REPLICATION_SSLMODE=prefer' \
  --env 'REPLICATION_HOST=master' --env 'REPLICATION_PORT=5432'  \
  --env 'REPLICATION_USER=repluser' --env 'REPLICATION_PASS=repluserpass' \
  absolootly/docker-postgresql:latest
```

The difference between a slave and a snapshot is that a slave is read-only and updated whenever the master data is updated (streaming replication), while a snapshot is read-write and is not updated after the initial snapshot of the data from the master.

This is useful for developers to quickly snapshot the current state of a live database and use it for development/debugging purposes without altering the database on the live instance.

## Creating a backup

Just as the case of setting up a slave node or generating a snapshot, you can also create a backup of the data on the master by specifying `REPLICATION_MODE=backup`.

> The backups are generated with [pg_basebackup](http://www.postgresql.org/docs/9.4/static/app-pgbasebackup.html) using the replication protocol.

Once the master node is created as specified in [Setting up a replication cluster](#setting-up-a-replication-cluster), you can create a point-in-time backup using:

```bash
docker run --name postgresql-backup -it --rm \
  --link postgresql-master:master \
  --env 'REPLICATION_MODE=backup' --env 'REPLICATION_SSLMODE=prefer' \
  --env 'REPLICATION_HOST=master' --env 'REPLICATION_PORT=5432'  \
  --env 'REPLICATION_USER=repluser' --env 'REPLICATION_PASS=repluserpass' \
  --volume /srv/docker/backups/postgresql.$(date +%Y%m%d%H%M%S):/var/lib/postgresql \
  absolootly/docker-postgresql:latest
```

Once the backup is generated, the container will exit and the backup of the master data will be available at `/srv/docker/backups/postgresql.XXXXXXXXXXXX/`. Restoring the backup involves starting a container with the data in `/srv/docker/backups/postgresql.XXXXXXXXXXXX`.

## Command-line arguments

You can customize the launch command of PostgreSQL server by specifying arguments for `postgres` on the `docker run` command. For example the following command enables connection logging:

```bash
docker run --name postgresql -itd --restart always \
  absolootly/docker-postgresql:latest -c log_connections=on
```

Please refer to the documentation of [postgres](http://www.postgresql.org/docs/9.4/static/app-postgres.html) for the complete list of available options.

## Logs

By default the PostgreSQL server logs are sent to the standard output. Using the [Command-line arguments](#command-line-arguments) feature you can configure the PostgreSQL server to send the log output to a file using the `-c logging_collector=on` argument:

```bash
docker run --name postgresql -itd --restart always \
  absolootly/docker-postgresql:latest -c logging_collector=on
```

To access the PostgreSQL logs you can use `docker exec`. For example:

```bash
docker exec -it postgresql tail -f /var/log/postgresql/postgresql-9.4-main.log
```

# UID/GID mapping

The files and processes created by the container are owned by the `postgres` user that is internal to the container. In the absense of user namespace in docker the UID and GID of the containers `postgres` user may have different meaning on the host.

For example, a user on the host with the same UID and/or GID as the `postgres` user of the container will be able to access the data in the persistent volumes mounted from the host as well as be able to KILL the `postgres` server process started by the container.

To circumvent this issue you can specify the UID and GID for the `postgres` user of the container using the `USERMAP_UID` and `USERMAP_GID` variables respectively.

For example, if you want to assign the `postgres` user of the container the UID and GID `999`:

```bash
docker run --name postgresql -itd --restart always \
  --env 'USERMAP_UID=999' --env 'USERMAP_GID=999' \
  absolootly/docker-postgresql:latest
```

# Maintenance

## Upgrading

To upgrade to newer releases:

  1. Download the updated Docker image:

  ```bash
  docker pull absolootly/docker-postgresql:latest
  ```

  2. Stop the currently running image:

  ```bash
  docker stop postgresql
  ```

  3. Remove the stopped container

  ```bash
  docker rm -v postgresql
  ```

  4. Start the updated image

  ```bash
  docker run --name postgresql -itd \
    [OPTIONS] \
    absolootly/postgresql:latest
  ```

## Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using Docker version `1.3.0` or higher you can access a running containers shell by starting `bash` using `docker exec`:

```bash
docker exec -it postgresql bash
```
