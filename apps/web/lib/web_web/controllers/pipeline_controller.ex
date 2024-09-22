defmodule WebWeb.PipelineController do
  use WebWeb, :controller

  @pubsub DocumentPipeline.PubSub
  @topic "pipeline_messages"

  @pipeline_path Application.compile_env(:document_pipeline, :pipeline_path)
  @input_path Application.compile_env(:document_pipeline, :input_path)
  @output_path Application.compile_env(:document_pipeline, :output_path)

  def run(conn, _params) do
    IO.inspect(@pipeline_path, label: "scripts_path")

    Task.start(fn ->
      {:ok, _pid} =
        DocumentPipeline.DynamicSupervisor.start_child(@pipeline_path, @input_path, @output_path)
    end)

    conn
    |> put_status(200)
    |> json(%{})
  end

  def stream_status(conn, _params) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> send_chunked(200)

    Phoenix.PubSub.subscribe(@pubsub, @topic)
    stream_messages(conn)
  end

  defp stream_messages(conn) do
    receive do
      {:pipeline_message, execution_id, event} ->
        json = Jason.encode!(Map.merge(%{execution_id: execution_id}, event))

        case chunk(conn, "data: #{json}\n\n") do
          {:ok, conn} -> stream_messages(conn)
          {:error, :closed} -> conn
        end
    after
      600_000 ->
        json = Jason.encode!(%{event: "timeout", data: "No updates received for 600 seconds"})
        chunk(conn, "data: #{json}\n\n")
        conn
    end
  end
end
