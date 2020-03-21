postgre:
   psql --host=localhost --port=5432 --username=starcraft  --dbname=denos

start:
	rails server

start-db:
	docker-compose up

stop-db:
	docker-compose down
 
