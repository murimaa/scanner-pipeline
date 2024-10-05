defmodule DocumentPipeline.FileWatcher do
  use GenServer
  require Logger

  def start_link({directory, pipeline_name}) do
    GenServer.start_link(__MODULE__, {directory, pipeline_name}, name: __MODULE__)
  end

  def init({directory, pipeline_name}) do
    {:ok, %{directory: directory, pipeline_name: pipeline_name, watcher_pid: nil},
     {:continue, :start_watcher}}
  end

  def handle_continue(:start_watcher, state) do
    with :ok <- File.mkdir_p(state.directory),
         {:ok, watcher_pid} <- FileSystem.start_link(dirs: [state.directory]),
         :ok <- FileSystem.subscribe(watcher_pid) do
      {:noreply, %{state | watcher_pid: watcher_pid}}
    else
      {:error, reason} ->
        Logger.error("Failed to start file watcher: #{inspect(reason)}")
        {:stop, :normal, state}
    end
  end

  def handle_info(
        {:file_event, watcher_pid, {path, [:created]}},
        %{watcher_pid: watcher_pid, pipeline_name: pipeline_name} = state
      ) do
    Logger.info("New file detected: #{path}")

    Task.start(fn ->
      wait_for_file_size_stabilization(path)

      {:ok, _pid} =
        DocumentPipeline.DynamicSupervisor.start_child(pipeline_name, path)
    end)

    {:noreply, state}
  end

  def handle_info(
        {:file_event, watcher_pid, {_path, _events}},
        %{watcher_pid: watcher_pid} = state
      ) do
    {:noreply, state}
  end

  def handle_info({:file_events, _watcher_pid, _events}, state) do
    {:noreply, state}
  end

  defp wait_for_file_size_stabilization(path, attempts \\ 10, delay \\ 1000)

  defp wait_for_file_size_stabilization(path, 0, _),
    do: Logger.warning("File size did not stabilize: #{path}")

  defp wait_for_file_size_stabilization(path, attempts, delay) do
    size = File.stat!(path).size
    Process.sleep(delay)
    new_size = File.stat!(path).size

    if size == new_size do
      :ok
    else
      wait_for_file_size_stabilization(path, attempts - 1, delay)
    end
  end
end
