# DocumentPipeline

## Sample scans and output
To try locally (without using scanner), first copy some images of scanned pages (images, not pdfs) to docker-compose-example/sample/input.
These are loaded into the app when you press "Scan" to simulate scanning.

PDFs, processed scans and thumbnails endup in `dev_output` directory.

## Running locally with sample pipeline

### Setup
Install elixir and nodejs, also preferrably imagemagick to run the pipelines.

### Start
```sh
mix phx.server
```
Go to http://localhost:4000/

## Running with docker
`SECRET_KEY_BASE` environment variable required. It is a random string.
Make sure you have that defined in `.env` file or in `docker-compose.yml`.

### Sample pipelines
Docker-compose file:
`docker-compose-examples/pixma-mx925/docker-compose.yml`.
Start with:
```sh
docker compose up --build
```


### Canon Pixma MX925
Docker-compose file:
`docker-compose-examples/pixma-mx925/docker-compose.yml`.
Either start the project in place or copy docker-compose.yml and
subdirectories to another directory.

If you copy the docker-compose file to another directory, fix
context path of app-base to point to the project root. Copy example pipeline scripts and update path references.

Fill in your PRINTER_IP in the docker-compose file.

In the directory of your docker-compose.yml file:
```sh
docker compose up --build
```




## Deprecated method from console, no web UI
(not updated in a while, doesn't work)
```sh
mix run --no-halt -e "DocumentPipeline.Client.start_pipeline()"
```
