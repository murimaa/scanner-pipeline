defmodule WebWeb.ConsoleController do
  use WebWeb, :controller

  @pubsub DocumentPipeline.PubSub
  @topic "pipeline_messages"

  def status_stream(conn, _params) do
    Phoenix.PubSub.subscribe(@pubsub, "#{@topic}:*")

    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> send_chunked(200)

    # Send cached messages
    get_cached_messages()
    |> Enum.each(fn {:pipeline_message, execution_id, event} ->
      json = Jason.encode!(Map.merge(%{execution_id: execution_id}, event))
      chunk(conn, "data: #{json}\n\n")
    end)

    stream_messages(conn)
  end

  defp stream_messages(conn) do
    receive do
      {:pipeline_message, execution_id, event} ->
        json = Jason.encode!(Map.merge(%{execution_id: execution_id}, event))

        case chunk(conn, "data: #{json}\n\n") do
          {:ok, conn} ->
            stream_messages(conn)

          {:error, "closed"} ->
            conn
        end
    after
      600_000 ->
        json = Jason.encode!(%{event: "timeout", data: "No updates received for 600 seconds"})
        chunk(conn, "data: #{json}\n\n")
        conn
    end
  end

  defp get_cached_messages do
    DocumentPipeline.DynamicSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.flat_map(fn {_, pid, _, _} ->
      DocumentPipeline.Server.get_log(pid)
    end)
    |> Enum.sort_by(fn {datetime, _message} -> datetime end)
    |> Enum.map(fn {_datetime, message} -> message end)
  end
end
