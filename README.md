# Assignment 3

This is the code for the assignment 3 of the course software architecture. The application is containerized using Docker and Docker Compose.

## Report

Link to google drive: [Report] https://docs.google.com/document/d/1-YAgeN7pZHTizsOCwmjUrvDcMj4giBkZ9AYvvMNJYtg/edit?usp=sharing

## Prerequisites

- Docker

## Getting Started

### Clone the Repository

First, clone this repository to your local machine

### Build and Start the Containers

To build and start the application and Cassandra containers, run (changing the docker compose according to wich services do you want vanilla docker-compose is web+cassandra docker-compose-full encases all services and then we have 3 separate docker composes for each serice independently togethetr with web and cassandra):

```
 docker-compose up --build
```

EXAMPLE REDIS 
Start + redis run:
```
 docker-compose -f docker-compose-redis.yml up --build
```
para sacar metricas
```
docker stats --no-stream > metrics.txt
```
This command will:

- Build the Docker image for the Rails app.
- Start Cassandra and set up the keyspace and tables.
- Start the Rails application server.

### Accessing the Application

Once the containers are up and running, you can access the Rails application at:

http://localhost:3000

### Seeding the DB

-Go into the terminal of the rails container (the exec tab)
-run the following command (NOTE: elastic db is only when elastic search is being used)

```
 rails db:seed
 rails elastic:seed

```

### Stopping the Containers

To stop and remove the containers, use:

```
 docker-compose down
```

This will stop and remove the running containers but will keep your data intact.
