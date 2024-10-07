defmodule WebWeb.PipelineController do
  use WebWeb, :controller

  @pubsub DocumentPipeline.PubSub
  @topic "pipeline_messages"

  def get_scan_config(conn, _params) do
    scan_config = Web.Config.scan_config()
    json(conn, scan_config)
  end

  def get_export_config(conn, _params) do
    scan_config = Web.Config.export_config()
    json(conn, scan_config)
  end

  def scan(conn, %{"pipeline" => pipeline}) do
    with true <- pipeline in Web.Config.scan_pipelines() do
      Task.start(fn ->
        {:ok, _pid} =
          DocumentPipeline.DynamicSupervisor.start_child(
            pipeline,
            Path.join(Application.get_env(:document_pipeline, :input_path), pipeline)
          )
      end)

      conn
      |> put_status(200)
      |> json(%{})
    else
      _ ->
        conn
        |> send_resp(:bad_request, "")
        |> halt()
    end
  end

  def export_document(conn, %{"pipeline" => pipeline, "pages" => pages}) do
    with true <- pipeline in Web.Config.export_pipelines() do
      case validate_pages(pages) do
        {:ok, valid_pages} ->
          # All pages are valid, proceed with PDF generation
          Task.start(fn ->
            export_task(pipeline, valid_pages)
          end)

          conn
          |> put_status(200)
          |> json(%{message: "PDF generation started"})

        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: reason})
          |> halt()
      end
    end
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

  defp wait_for_pipeline_to_finish(execution_id) do
    receive do
      {:pipeline_message, ^execution_id, %{event: :pipeline_failed, pipeline: _}} ->
        :error

      {:pipeline_message, ^execution_id, %{event: :pipeline_finished, pipeline: _}} ->
        :ok

      _ ->
        wait_for_pipeline_to_finish(execution_id)
    end
  end

  defp delete_page_and_thumbnail(page_relative_path) do
    case validate_and_get_full_path(page_relative_path) do
      {:ok, full_path} ->
        case File.rm(full_path) do
          :ok ->
            ThumbnailCache.delete_thumbnail(full_path)
            :ok

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_and_get_full_path(page_relative_path) do
    with {:ok, page_relative_path} <- Path.safe_relative(page_relative_path),
         true <- Path.dirname(page_relative_path) in Web.Config.scan_pipelines(),
         full_path <-
           Path.join([Application.get_env(:document_pipeline, :output_path), page_relative_path]),
         true <- File.exists?(full_path) do
      {:ok, full_path}
    else
      false -> {:error, :not_found}
      :error -> {:error, :invalid_path}
      _ -> {:error, :not_found}
    end
  end

  defp validate_pages(pages) do
    case Enum.reduce_while(pages, [], &validate_and_accumulate_page/2) do
      {:error, reason} -> {:error, reason}
      valid_pages -> {:ok, Enum.reverse(valid_pages)}
    end
  end

  defp validate_and_accumulate_page(page, acc) do
    case validate_and_get_full_path(page) do
      {:ok, full_path} -> {:cont, [full_path | acc]}
      {:error, _reason} -> {:halt, {:error, "Invalid page filename: #{page}"}}
    end
  end

  defp export_task(pipeline, valid_pages) do
    unique_string = :crypto.strong_rand_bytes(16) |> Base.url_encode64() |> binary_part(0, 16)
    temp_dir = Path.join([System.tmp_dir!(), unique_string])
    File.mkdir_p!(temp_dir)

    Enum.each(valid_pages, fn source_path ->
      dest_path = Path.join(temp_dir, Path.basename(source_path))
      File.cp!(source_path, dest_path)
    end)

    {:ok, pid} = DocumentPipeline.DynamicSupervisor.start_child(pipeline, temp_dir)
    execution_id = DocumentPipeline.Server.get_execution_id(pid)
    Phoenix.PubSub.subscribe(@pubsub, "#{@topic}:#{execution_id}")

    case wait_for_pipeline_to_finish(execution_id) do
      :ok ->
        Enum.each(valid_pages, fn page_full_path ->
          :ok = File.rm(page_full_path)
          ThumbnailCache.delete_thumbnail(page_full_path)
        end)

      :error ->
        nil
    end

    File.rm_rf!(temp_dir)
  end
end
