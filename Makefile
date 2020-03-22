postgre:
   psql --host=localhost --port=5432 --username=starcraft  --dbname=denos

test:
	bundle exec rspec

integration:
	bundle exec rspec spec/lib/*

start:
	bundle exec rails server

start-db:
	docker-compose up

stop-db:
	docker-compose down
 
