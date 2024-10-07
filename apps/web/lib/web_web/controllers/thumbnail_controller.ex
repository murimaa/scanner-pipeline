defmodule WebWeb.ThumbnailController do
  use WebWeb, :controller

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

  def serve_thumbnail(conn, %{"page" => page}) do
    with {:ok, thumbnail_file} <-
           ThumbnailCache.get_thumbnail(
             Path.join(Application.get_env(:document_pipeline, :output_path), page)
           ) do
      content_type = MIME.from_path(thumbnail_file)

      conn
      |> put_resp_content_type(content_type)
      |> send_file(200, thumbnail_file)
    else
      _error ->
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
    thumbnails =
      list_pages() |> Enum.map(fn page -> %{name: page, url: thumbnail_url(page)} end)

    json = Jason.encode!(%{event: "thumbnails", data: thumbnails})
    chunk(conn, "data: #{json}\n\n")
  end

  def list_pages do
    scan_files =
      scan_dirs()
      |> Enum.flat_map(fn dir ->
        with {:ok, files} <- File.ls(dir) do
          Enum.map(files, &Path.join(dir, &1))
        else
          _ -> []
        end
      end)

    scan_files
    # Sort by filename (ignoring directory)
    |> Enum.sort(&(Path.basename(&1) <= Path.basename(&2)))
    |> Enum.map(
      &Path.relative_to(
        &1,
        Application.get_env(:document_pipeline, :output_path)
      )
    )
  end

  defp thumbnail_url(filename) do
    "/thumbnail?page=#{filename}"
  end

  defp scan_dirs(),
    do:
      Web.Config.scan_pipelines()
      |> Enum.map(&Path.join(Application.get_env(:document_pipeline, :output_path), &1))
end
