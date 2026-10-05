# README

A basic upload platform that initiates a job based ETL pipeline for mock healthcare data.

## Prerequisites
* Docker (https://docs.docker.com/get-docker/) (v20.10+)
* Docker Compose (https://docs.docker.com/compose/install/) (v2.0+)
* Git (https://git-scm.com/downloads)

## Installation
1. Clone the repository
```
    git clone <repository-url>
    cd ava
```
2. Set up a .env (optional)
```
DATABASE_USER=ava
DATABASE_PASSWORD=password
DATABASE_NAME=ava_development
DATABASE_TEST_NAME=ava_test
DATABASE_PORT=5432
```
3. Build and start services
```
docker compose up --build -d
docker compose exec web bin/rails db:prepare
```

After these steps it will be available at http://localhost:3000

## Usage
* Migrations page provides a list of previously completed migrations
* More directs to a show page with provides details on the specifics of execution, along with a list of critical errors, and non blocking warnings
* Upload directs the user to a page with an upload input and a submit button which only accepts CSV files < 1GB with the valid headers
* Patients page provides a view of uploaded patients, filtered to exclude expired SCD Type 2 entries (as all use cases for this data would)

## Schema
Expects an uploaded CSV with the following fields
#### Required

* health identifier: A number identifer for the patient.  Leading 0's are preserved.
* health identifier province: A Canadian provice name or shorthand (ex. British Columbia or BC)

#### Optional
* first name
* last name
* middle name
* phone	email
* address 1
* address 2	
* address province
* address city
* address postal code
* date of birth
* sex

## Idempotency
* health identifier & health identifier province are used as a key, with only 1 active row valid for each
* Raw data fields are hashd and compared against existing Patients field, with matches being skipped to avoid re-import
* Past data is preserved via the SCD (slwoly schanging data) Type 2 pattern.  On a unique hash, but taken id/province combo being uploaded, a new Patient row will be inserted and the old row expired