defmodule WebWeb.ThumbnailController do
  use WebWeb, :controller

  @thumbnail_dir Path.join([
                   Application.compile_env(:document_pipeline, :output_path),
                   "thumbnail"
                 ])
  @page_dir Path.join([
              Application.compile_env(:document_pipeline, :output_path),
              "scan"
            ])
  # Check for changes every 1 seconds
  @check_interval 1000

  def thumbnail_stream(conn, _params) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> send_chunked(200)

    send_current_thumbnails(conn)
    stream_thumbnails(conn)
  end

  def serve_thumbnail(conn, %{"filename" => filename}) do
    file_path = Path.join(@thumbnail_dir, filename)

    if File.exists?(file_path) and image?(filename) do
      content_type = MIME.from_path(filename)

      conn
      |> put_resp_content_type(content_type)
      |> send_file(200, file_path)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Thumbnail not found"})
    end
  end

  defp stream_thumbnails(conn) do
    Process.send_after(self(), :check_thumbnails, @check_interval)

    receive do
      :check_thumbnails ->
        case send_current_thumbnails(conn) do
          {:ok, conn} ->
            stream_thumbnails(conn)

          {:error, "closed"} ->
            conn
        end
    end
  end

  defp send_current_thumbnails(conn) do
    thumbnails = list_thumbnails()
    json = Jason.encode!(%{event: "thumbnails", data: thumbnails})
    chunk(conn, "data: #{json}\n\n")
  end

  defp list_thumbnails do
    @thumbnail_dir
    |> File.ls!()
    |> Enum.filter(&image?/1)
    |> Enum.map(&%{name: &1, url: thumbnail_url(&1)})
  end

  defp image?(filename) do
    String.ends_with?(filename, ~w(.jpg .jpeg .png .gif .webp))
  end

  defp thumbnail_url(filename) do
    "/thumbnails/#{filename}"
  end
end
