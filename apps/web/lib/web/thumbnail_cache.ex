defmodule ThumbnailCache do
  use GenServer
  require Logger

  @thumbnail_pipeline "thumbnail"
  @table_name :thumbnail_cache
  @max_retries 3
  @timeout 30_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table_name, [:set, :public, :named_table])
    {:ok, %{}}
  end

  def get_thumbnail(image_file) do
    GenServer.call(__MODULE__, {:get_thumbnail, image_file})
  end

  def delete_thumbnail(image_file) do
    GenServer.call(__MODULE__, {:delete_thumbnail, image_file})
  end

  def handle_call({:get_thumbnail, image_file}, _from, state) do
    case :ets.lookup(@table_name, image_file) do
      [{^image_file, thumbnail_path}] ->
        {:reply, {:ok, thumbnail_path}, state}

      [] ->
        case create_thumbnail(image_file) do
          {:ok, thumbnail_path} ->
            :ets.insert(@table_name, {image_file, thumbnail_path})
            {:reply, {:ok, thumbnail_path}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  def handle_call({:delete_thumbnail, image_file}, _from, state) do
    case :ets.lookup(@table_name, image_file) do
      [{^image_file, thumbnail_path}] ->
        :ets.delete(@table_name, image_file)
        delete_file_result = delete_file(thumbnail_path)
        {:reply, delete_file_result, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  defp create_thumbnail(image_file) do
    create_thumbnail_with_retry(image_file, 1)
  end

  defp create_thumbnail_with_retry(image_file, attempt) when attempt <= @max_retries do
    temp_dir = System.tmp_dir!()

    random_file_basename =
      "thumbnail_#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}"

    img_tmp_file = Path.join(temp_dir, "#{random_file_basename}#{Path.extname(image_file)}")
    File.cp!(image_file, img_tmp_file)

    case DocumentPipeline.DynamicSupervisor.start_child(@thumbnail_pipeline, img_tmp_file) do
      {:ok, pid} ->
        _execution_id = DocumentPipeline.Server.get_execution_id(pid)
        monitor_ref = Process.monitor(pid)

        receive do
          {:DOWN, ^monitor_ref, :process, ^pid, :normal} ->
            thumbnail = find_matching_thumbnail(img_tmp_file)

            if thumbnail != nil do
              {:ok, thumbnail}
            else
              Logger.warn("Thumbnail not created on attempt #{attempt}. Retrying...")
              create_thumbnail_with_retry(image_file, attempt + 1)
            end

          {:DOWN, ^monitor_ref, :process, ^pid, reason} ->
            Logger.warn(
              "Thumbnail creation failed on attempt #{attempt} with reason: #{inspect(reason)}. Retrying..."
            )

            create_thumbnail_with_retry(image_file, attempt + 1)
        after
          @timeout ->
            Process.exit(pid, :kill)
            Logger.warn("Thumbnail creation timed out on attempt #{attempt}. Retrying...")
            create_thumbnail_with_retry(image_file, attempt + 1)
        end

      {:error, reason} ->
        Logger.error(
          "Failed to start thumbnail pipeline on attempt #{attempt}: #{inspect(reason)}"
        )

        create_thumbnail_with_retry(image_file, attempt + 1)
    end
  end

  defp create_thumbnail_with_retry(_image_file, attempt) do
    Logger.error("Thumbnail creation failed after #{@max_retries} attempts")
    {:error, :max_retries_exceeded}
  end

  def find_matching_thumbnail(image_file) do
    basename = Path.basename(image_file, Path.extname(image_file))

    thumbnail_path =
      Path.join([Application.get_env(:document_pipeline, :output_path), @thumbnail_pipeline])

    thumbnail_filename =
      thumbnail_path
      |> File.ls!()
      |> Enum.find(fn thumbnail_file ->
        Path.basename(thumbnail_file, Path.extname(thumbnail_file)) == basename
      end)

    if thumbnail_filename != nil, do: Path.join(thumbnail_path, thumbnail_filename), else: nil
  end

  defp delete_file(path) do
    case File.rm(path) do
      :ok -> {:ok, :deleted}
      {:error, reason} -> {:error, reason}
    end
  end
end
