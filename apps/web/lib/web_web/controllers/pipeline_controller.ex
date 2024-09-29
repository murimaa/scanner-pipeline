defmodule WebWeb.PipelineController do
  use WebWeb, :controller

  @pubsub DocumentPipeline.PubSub
  @topic "pipeline_messages"

  @pipeline_path Application.compile_env(:document_pipeline, :pipeline_path)
  @input_path Application.compile_env(:document_pipeline, :input_path)
  @page_dir Path.join([
              Application.compile_env(:document_pipeline, :output_path),
              "scan"
            ])

  @thumbnail_dir Path.join([
                   Application.compile_env(:document_pipeline, :output_path),
                   "thumbnail"
                 ])
  @page_dir Path.join([
              Application.compile_env(:document_pipeline, :output_path),
              "scan"
            ])
  def scan(conn, _params) do
    Task.start(fn ->
      {:ok, _pid} =
        DocumentPipeline.DynamicSupervisor.start_child("scan", @input_path)
    end)

    conn
    |> put_status(200)
    |> json(%{})
  end

  def generate_pdf(conn, params) do
    files = params["files"]

    unique_string = :crypto.strong_rand_bytes(16) |> Base.url_encode64() |> binary_part(0, 16)
    temp_dir = Path.join([System.tmp_dir!(), unique_string])

    File.mkdir_p!(temp_dir)

    Enum.each(files, fn file ->
      source_path = Path.join(@page_dir, "#{file}.png")
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

  def delete_page(conn, %{"filename" => filename}) do
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
    thumbnail_filename = "#{filename}.webp"
    original_filename = "#{filename}.png"
    thumbnail_full_path = Path.join([@thumbnail_dir, thumbnail_filename])
    original_full_path = Path.join([@page_dir, original_filename])

    with {:ok, _} <- Path.safe_relative(filename, @thumbnail_dir),
         {:ok, _} <- Path.safe_relative(filename, @page_dir),
         true <- File.exists?(thumbnail_full_path) and File.exists?(original_full_path),
         # true <- image?(filename),
         :ok <- File.rm(thumbnail_full_path),
         :ok <- File.rm(original_full_path) do
      :ok
    else
      :error -> {:error, :invalid_path}
      false -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
end
