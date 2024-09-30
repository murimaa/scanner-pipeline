defmodule Web.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp scan_originals_path,
    do:
      Path.join([
        Application.get_env(:document_pipeline, :output_path),
        "scan"
      ])

  @impl true
  def start(_type, _args) do
    children = [
      WebWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Web.PubSub},
      # Start the Finch HTTP client for sending emails
      # {Finch, name: Web.Finch},
      {DocumentPipeline.FileWatcher, {scan_originals_path(), "thumbnail"}},
      # Start a worker by calling: Web.Worker.start_link(arg)
      # {Web.Worker, arg},
      # Start to serve requests, typically the last entry
      WebWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Web.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
