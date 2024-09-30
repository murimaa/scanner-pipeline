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
```sh
docker build -t document_pipeline:latest .
cd docker-compose-example && docker compose up --build
```
