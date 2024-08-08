# Assignement 1

This is the code for the assignment 1 of the course software architecture. The application is containerized using Docker and Docker Compose.

## Prerequisites

- Docker

## Getting Started

### Clone the Repository

First, clone this repository to your local machine

### Build and Start the Containers

To build and start the application and Cassandra containers, run:

// docker-compose up --build

This command will:

- Build the Docker image for the Rails app.
- Start Cassandra and set up the keyspace and tables.
- Start the Rails application server.

### Accessing the Application

Once the containers are up and running, you can access the Rails application at:

http://localhost:3000

### Seeding the DB

### Stopping the Containers

To stop and remove the containers, use:

// docker-compose down

This will stop and remove the running containers but will keep your data intact.
