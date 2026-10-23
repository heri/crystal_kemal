# Crystal/Kemal JSON API Server

This is a JSON API server built with [Kemal](https://kemalcr.com/) in [Crystal](https://crystal-lang.org/). It is designed to be compared with an Actix-web server. While Actix-web is known for its safety and speed, Kemal offers faster development and easier maintenance.

Read more : https://studiozenkai.com/post/crystal-high-performance/

## Getting Started

### Prerequisites

Make sure you have Crystal installed on your machine. You can install it using Homebrew:

```sh
brew install crystal
```

### Installation
Clone the repository and navigate into the project directory:

```sh
git clone git@github.com:heri/crystal_pure_api.git
cd crystal_pure_api
```

Install the required dependencies:
```sh
shards install
psql -U postgres
CREATE DATABASE profiling;
\c profiling
CREATE TABLE users (id SERIAL PRIMARY KEY, firstName VARCHAR(255));
```

Seed the table with the 10,000 rows the `/db` benchmark endpoint reads from:
```sh
bin/seed
```

### Running the Application
Compile the application:
```sh
crystal build main.cr --release
```

Crystal runs single-threaded per process, so `main.cr` binds with `reuse_port` and `bin/server` starts one worker process per CPU core, letting the kernel load-balance connections across them:
```sh
KEMAL_PORT=3000 bin/server
```

Set `WORKERS` to override the worker count instead of using all cores.

Each worker keeps its own Postgres connection pool, sized by `DB_POOL_SIZE` (default 25) so connections are pre-warmed instead of opened and closed on demand under load.

The server should now be running and accessible at http://localhost:3000.

Endpoints
* GET /json: Returns a static JSON payload with no database access. Mirrors TechEmpower's JSON Serialization test.
* GET /db: Fetches one row out of the 10,000-row users table by a server-generated random id. Mirrors TechEmpower's Single Database Query test.
* GET /users: Returns a list of users in HTML format.
* POST /webhook: Updates a user's first name. Expects a JSON payload with firstName and Id.

## Contributing
Feel free to submit issues and pull requests.

## License
This project is licensed under the MIT License.

## Who is behind this

Heri is a software engineer, photographer, father and Montréaler. Building in the open — see more projects at [studiozenkai.com](https://studiozenkai.com).
