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

### Thoughts

Some thoughts which could not be expressed as comments in code but may be something the reviewer may have desired to ask:

- Why not ensure all ips are unique across all clusters?

	The project has the benefit that we are creating dummy data which are made to fit the necessary requirements, making it easier to handle, without including
	much code to ensure unique-ness. But then again, there is not necessary a clear definition, if the uniqueness is to be on a per-cluster basis or across
	multiple clusters (which by definition in this project are in different areas). 

	I am not sure sure if that is something to be done in code or something to be 
	fixed during architecture in a real world scenarios where we ensure the IP CIDR are unique across a range for each cluster. In essense, this is a question I feel that may be suitable during architecture of a real-life DNS
	system. 

- Its a test project why reload records on every controller request ?

	As I was not sure if the service would be scaled or if we will have human
	editting of dns records during test (hard to see how since it would be my API keys, but let's say it is), then to ensure the in-memory cache never
	get's stale, then reloading such as the critical junction is needed. We could optimize these away if this conditions are false though.

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

```bash
DATABASE_URL="postgres://localhost:5432"

TEST_DATABASE_NAME=denos_test

# Should be the same as value set in docker-compose for postgresql
TEST_DATABASE_USER=starcraft
TEST_DATABASE_PASSWORD=starcraft

DEV_DATABASE_NAME=denos_dev

# Should be the same as value set in docker-compose for postgresql
DEV_DATABASE_USER=starcraft
DEV_DATABASE_PASSWORD=starcraft

DATABASE_NAME=denos

# Should be the same as value set in docker-compose for postgresql
DATABASE_USER=starcraft
DATABASE_PASSWORD=starcraft

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

