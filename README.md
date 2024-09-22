# DocumentPipeline

**TODO: Add description**
Test run:
```sh
mix run --no-halt -e "DocumentPipeline.Client.start_pipeline()"
```

Via web endpoint:
```sh
mix phx.server
curl -N -X POST http://localhost:4000/run_pipeline
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `document_pipeline` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:document_pipeline, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/document_pipeline>.

Svelte configuration guide:
https://github.com/tonydangblog/phoenix-inertia-svelte
