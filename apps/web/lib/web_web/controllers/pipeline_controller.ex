defmodule WebWeb.PipelineController do
  use WebWeb, :controller

  @pubsub DocumentPipeline.PubSub
  @topic "pipeline_messages"

  def scan(conn, _params) do
    Task.start(fn ->
      {:ok, _pid} =
        DocumentPipeline.DynamicSupervisor.start_child(
          "scan",
          Application.get_env(:document_pipeline, :input_path)
        )
    end)

    conn
    |> put_status(200)
    |> json(%{})
  end

  def generate_pdf(conn, params) do
    originals_dir =
      Path.join([
        Application.get_env(:document_pipeline, :output_path),
        "scan"
      ])

    unique_string = :crypto.strong_rand_bytes(16) |> Base.url_encode64() |> binary_part(0, 16)
    temp_dir = Path.join([System.tmp_dir!(), unique_string])

    files = params["files"]

    File.mkdir_p!(temp_dir)

    Enum.each(files, fn file ->
      source_path = Path.join(originals_dir, "#{file}.png")
      dest_path = Path.join(temp_dir, "#{file}.png")
      File.cp!(source_path, dest_path)
    end)

    Task.start(fn ->
      {:ok, pid} =
        DocumentPipeline.DynamicSupervisor.start_child("pdf", temp_dir)

      execution_id = DocumentPipeline.Server.get_execution_id(pid)
      Phoenix.PubSub.subscribe(@pubsub, "#{@topic}:#{execution_id}")

      case wait_for_pipeline_to_finish() do
        :ok ->
          Enum.each(files, fn file ->
            delete_page_and_thumbnail(file)
          end)

        :error ->
          nil
      end

      File.rm_rf!(temp_dir)
    end)

    conn
    |> put_status(200)
    |> json(%{message: "PDF generation started"})
  end

  def delete_page(conn, %{"page" => filename}) do
    case delete_page_and_thumbnail(filename) do
      :ok ->
        send_resp(conn, :no_content, "")

      {:error, :invalid_path} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Invalid file path"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Thumbnail or original file not found or is not an image"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to delete files: #{reason}"})
    end
  end

  defp wait_for_pipeline_to_finish() do
    receive do
      {:pipeline_message, _execution_id, %{event: :pipeline_failed, pipeline: _}} ->
        :error

      {:pipeline_message, _execution_id, %{event: :pipeline_finished, pipeline: _}} ->
        :ok

      _ ->
        wait_for_pipeline_to_finish()
    end
  end

  defp delete_page_and_thumbnail(filename) do
    with {:ok, filename} <- Path.safe_relative(filename),
         true <- Path.dirname(filename) in Web.Config.scan_pipelines(),
         full_path <-
           Path.join([Application.get_env(:document_pipeline, :output_path), filename]),
         true <- File.exists?(full_path) do
      case File.rm(full_path) do
        :ok ->
          ThumbnailCache.delete_thumbnail(full_path)
          :ok

        {:error, reason} ->
          {:error, reason}
      end
    else
      false ->
        {:error, :not_found}

      :error ->
        # Path.safe_relative
        {:error, :invalid_path}

      _ ->
        {:error, :not_found}
    end
  end
end
