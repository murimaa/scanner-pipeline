# DocumentPipeline

Test run (not updated in a while, doesn't work):
```sh
mix run --no-halt -e "DocumentPipeline.Client.start_pipeline()"
```

Via web UI:
```sh
mix phx.server
Go to http://localhost:4000/
```

With docker:
Copy and edit the example docker-compose file
`docker-compose-examples/docker-compose-pixma-mx925.yml`.
Fix context path of app-base to point to the project root, and fill in PRINTER_IP.
Copy example pipeline scripts and update path references.

In the directory of your docker-compose.yml file:
```sh
docker compose up --build
```
