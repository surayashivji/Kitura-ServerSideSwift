## Project 2: Voting API

## Installation (MacOS)
1. Clone Repository
2. `cd` into **2votingapi** directory
2. Run `swift build && .build/debug/2votingapi`
3. Go to an available route (listed below) to see JSON from CouchDB database

#### Routes
1. `http://localhost:8090/polls/list` - GET request to list all polls
2. `` - POST request to create a new poll
3. `` - POST request to vote on an existing poll
4. `` - DELETE request to delete a poll from database