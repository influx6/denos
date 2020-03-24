# README
Project is based on dns management test required by ExpressVPN.

### Project Rquirements

The following setup was used during the development of this project:

- homebrew
- PostgreSQL
- ruby 2.6.5
- docker and docker-compose

You should be able to get most except for docker and docker-compose setup by running

```
make setup
```

### Database initialization

The project utilizes docker to boot up a sample PostgreSQL database for development
and testing, so ensure to have docker and docker compose setup, see [Docker Setup for Mac](https://docs.docker.com/docker-for-mac/).

You can easily boot-up database, by executing the ff:

```
make start-db

```

To setup database for development, testing or production, execute:

```
make db-setup env=development
```

Swap `development` for which ever environment you wish to setup


### How to run project locally

Once docker and database setup as describe in previous section is completed, we need to setup an `.env` file to host environment variables used by the application.

Add the following to an '.env' file:

```
TEST_DATABASE_NAME=denos_test
DEV_DATABASE_NAME=denos_dev
PROD_DATABASE_NAME=denos

# Should be the same as value set in docker-compose for postgresql
TEST_DATABASE_USER=starcraft
TEST_DATABASE_PASSWORD=starcraft

# Should be the same as value set in docker-compose for postgresql
DEV_DATABASE_USER=starcraft
DEV_DATABASE_PASSWORD=starcraft

# Should be the same as value set in docker-compose for postgresql
PROD_DATABASE_USER=starcraft
PROD_DATABASE_PASSWORD=starcraft

# Set whatever region you want (aws r53 is not region locked though)
AWS_REGION=ap-southeast-1

# Hosted zone to be used in server
AWS_HOSTED_ZONE=Z******************

# AWS access key id
AWS_ACCESS_KEY_ID=A*******************

# AWS access secret key
AWS_SECRET_ACCESS_KEY=U************************

```


To run server and db, simply execute the following:


```
make start
```

Navigate your browser to http://localhost:3000 and you should be ready to go.

### How to run the test suite

Provided within project is a combination of unit, functional and integration tests, to execute these:

```
make test
```

### Deployment

As required, the project will be deployed to provied heroku server.

