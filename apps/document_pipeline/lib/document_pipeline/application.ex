defmodule DocumentPipeline.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DocumentPipeline.DynamicSupervisor,
      {DocumentPipeline.MessageHandler, name: DocumentPipeline.MessageHandler}
    ]

    opts = [strategy: :one_for_one, name: DocumentPipeline.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
