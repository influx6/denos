# README
Project is based on dns management test required by ExpressVPN.

### Project Rquirements

The following setup was used during the development of this project:

- homebrew
- PostgreSQL
- ruby 2.6.5p114
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

Once docker and database setup as describe in previous section is complete, simply execute the following:


```
make start
```

Navigate your browser to http://localhost:3000 and you should be ready to go.

### How to run the test suite

Provider within project is a combination of unit, functional and integration tests, to execute:

```
make test
```

* Services (job queues, cache servers, search engines, etc.)

### Deployment

As required, the project will be deployed to provied heroku server.

