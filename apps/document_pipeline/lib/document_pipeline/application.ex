defmodule DocumentPipeline.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: DocumentPipeline.PipelineRegistry},
      {Registry, keys: :unique, name: DocumentPipeline.FileWatcherRegistry},
      {Phoenix.PubSub, name: DocumentPipeline.PubSub},
      DocumentPipeline.DynamicSupervisor
    ]

    opts = [strategy: :one_for_one, name: DocumentPipeline.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
