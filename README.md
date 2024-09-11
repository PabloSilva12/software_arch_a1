# Assignement 1

This is the code for the assignment 1 of the course software architecture. The application is containerized using Docker and Docker Compose.

## Report

Link to google drive: [Report]https://docs.google.com/document/d/1xbG_9fGG-n2w6ibhZuWz8iuyWyR-8N3GVGZpllFud8Y/edit?usp=sharing

## Prerequisites

- Docker

## Getting Started

### Clone the Repository

First, clone this repository to your local machine

### Build and Start the Containers

To build and start the application and Cassandra containers, run:

```
 docker-compose up --build
```

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
-run the following command

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
