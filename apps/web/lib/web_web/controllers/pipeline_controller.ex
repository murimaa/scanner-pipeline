defmodule WebWeb.PipelineController do
  use WebWeb, :controller

  def run(conn, _params) do
    my_pid = self()

    Task.start(fn ->
      {:ok, pid} = DocumentPipeline.DynamicSupervisor.start_child()
      DocumentPipeline.Server.run_pipeline(pid, my_pid)
    end)

    conn =
      conn
      |> put_resp_content_type("application/json-stream")
      |> send_chunked(200)

    {:ok, conn} = listen_for_progress(conn)
    conn
  end

  defp listen_for_progress(conn) do
    receive do
      {:script_started, script} ->
        json = Jason.encode!(%{event: "script_started", script: script})

        case chunk(conn, "#{json}\n") do
          {:ok, conn} -> listen_for_progress(conn)
          {:error, :closed} -> {:ok, conn}
        end

      {:script_finished, script} ->
        json = Jason.encode!(%{event: "script_finished", script: script})

        case chunk(conn, "#{json}\n") do
          {:ok, conn} -> listen_for_progress(conn)
          {:error, :closed} -> {:ok, conn}
        end

      {:script_failed, script, reason} ->
        json = Jason.encode!(%{event: "script_failed", script: script, reason: reason})
        chunk(conn, "#{json}\n")
        {:ok, conn}

      {:pipeline_failed, reason} ->
        json = Jason.encode!(%{event: "pipeline_failed", reason: reason})
        chunk(conn, "#{json}\n")
        {:ok, conn}

      :pipeline_finished ->
        json = Jason.encode!(%{event: "pipeline_finished"})
        chunk(conn, "#{json}\n")
        {:ok, conn}
    after
      600_000 ->
        json = Jason.encode!(%{event: "timeout", message: "No updates received for 600 seconds"})
        chunk(conn, "#{json}\n")
        {:ok, conn}
    end
  end
end
