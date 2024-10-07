defmodule DocumentPipeline.Server do
  use GenServer
  @pubsub DocumentPipeline.PubSub
  @topic "pipeline_messages"

  ## Client API

  def start_link({execution_id, pipeline_name, input_path, output_path}) do
    GenServer.start_link(__MODULE__, {execution_id, pipeline_name, input_path, output_path},
      name: via_tuple(execution_id)
    )
  end

  def child_spec({pipeline_name, input_path, output_path}) do
    execution_id = for _ <- 1..20, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

    output_path =
      if output_path == nil,
        do: Application.get_env(:document_pipeline, :output_path),
        else: output_path

    %{
      id: {__MODULE__, execution_id},
      start: {__MODULE__, :start_link, [{execution_id, pipeline_name, input_path, output_path}]},
      restart: :temporary
    }
  end

  ## Server Callbacks

  def init({execution_id, pipeline_name, input_path, output_path}) do
    {:ok,
     %{
       execution_id: execution_id,
       pipeline_name: pipeline_name,
       scripts_path:
         Path.join([Application.get_env(:document_pipeline, :pipeline_path), pipeline_name]),
       input_path: input_path,
       output_path: output_path,
       # Whether to create execution_id subdirs to output_path
       # Not configurable for now
       flat_output_dir: true,
       status: :initializing,
       current_script: nil,
       error: nil,
       log: []
     }, {:continue, :run_pipeline}}
  end

  def get_execution_id(pid) when is_pid(pid) do
    GenServer.call(pid, :get_execution_id)
  end

  def get_log(pid) when is_pid(pid) do
    GenServer.call(pid, :get_log)
  end

  def get_log(execution_id) do
    GenServer.call(via_tuple(execution_id), :get_log)
  end

  def handle_continue(:run_pipeline, state) do
    scripts_with_args = get_scripts(state)

    case scripts_with_args do
      [] ->
        state = send_progress(state, %{event: :pipeline_failed, pipeline: state.pipeline_name})
        {:stop, :error, %{state | status: :failed, error: "No scripts in pipeline"}}

      _ ->
        send(self(), {:run_next_script, scripts_with_args})
        {:noreply, %{state | status: :running, current_script: nil}}
    end
  end

  def handle_info({:run_next_script, []}, state) do
    state = send_progress(state, %{event: :pipeline_finished, pipeline: state.pipeline_name})
    cleanup_temp_files(state.execution_id)
    {:stop, :normal, %{state | status: :finished}}
  end

  def handle_info({:run_next_script, [{script, args, cwd} | rest]}, state) do
    my_pid = self()

    Task.start(fn ->
      result = run_script(script, args, cwd)
      send(my_pid, {:script_finished, script, result, rest})
    end)

    script_name = script |> Path.basename() |> Path.rootname()
    pipeline_name = state.pipeline_name

    state =
      send_progress(state, %{event: :script_started, pipeline: pipeline_name, script: script_name})

    {:noreply, %{state | current_script: script}}
  end

  def handle_info({:script_finished, script, result, remaining_scripts}, state) do
    script_name = script |> Path.basename() |> Path.rootname()
    pipeline_name = state.pipeline_name

    case result do
      :ok ->
        state =
          send_progress(state, %{
            event: :script_finished,
            pipeline: pipeline_name,
            script: script_name
          })

        send(self(), {:run_next_script, remaining_scripts})
        {:noreply, state}

      {:error, reason} ->
        state =
          send_progress(state, %{
            event: :script_failed,
            pipeline: pipeline_name,
            script: script_name
          })

        state = send_progress(state, %{event: :pipeline_failed, pipeline: pipeline_name})
        cleanup_temp_files(state.execution_id)
        {:stop, :error, %{state | status: :failed, error: reason}}
    end
  end

  def handle_call(:get_log, _from, %{log: log} = state) do
    {:reply, log, state}
  end

  def handle_call(:get_execution_id, _from, %{execution_id: execution_id} = state) do
    {:reply, execution_id, state}
  end

  def terminate(_reason, state) do
    cleanup_temp_files(state.execution_id)
  end

  ## Helper Functions

  defp via_tuple(execution_id) do
    {:via, Registry, {DocumentPipeline.PipelineRegistry, execution_id}}
  end

  defp get_scripts(%{
         execution_id: execution_id,
         pipeline_name: pipeline_name,
         scripts_path: scripts_path,
         input_path: input_path,
         output_path: output_path,
         flat_output_dir: flat_output_dir
       }) do
    scripts =
      Path.wildcard(Path.join(scripts_path, "*.sh"))
      |> Enum.sort()

    # Viimeisen skriptin indeksi
    last_index = length(scripts) - 1

    {script_tuples, _} =
      Enum.reduce(Enum.with_index(scripts), {[], input_path}, fn {script, index},
                                                                 {acc, prev_cwd} ->
        script_name = script |> Path.rootname() |> Path.basename()

        # Määritellään cwd
        cwd =
          if index == last_index do
            # Viimeisen skriptin cwd output_dir
            if flat_output_dir do
              Path.join([output_path, pipeline_name])
            else
              Path.join([output_path, pipeline_name, execution_id])
            end
          else
            Path.join([
              Application.get_env(:document_pipeline, :tmp_path),
              execution_id,
              script_name
            ])
          end

        # Luodaan tuple {script, args, cwd}
        tuple = {script, prev_cwd, cwd}

        {[tuple | acc], cwd}
      end)

    Enum.reverse(script_tuples)
  end

  defp cleanup_temp_files(execution_id) do
    temp_dir = Path.join([Application.get_env(:document_pipeline, :tmp_path), execution_id])
    File.rm_rf!(temp_dir)
  end

  defp run_script(script_path, args, cwd) do
    # IO.puts("Suoritetaan: #{script_path} #{args}")

    File.mkdir_p!(cwd)

    {output, exit_code} =
      if args == nil or args == "" do
        System.cmd("bash", [script_path], cd: cwd)
      else
        System.cmd("bash", [script_path, args], cd: cwd)
      end

    if exit_code == 0 do
      # IO.puts("Skripti suoritettu onnistuneesti: #{script_path}")
      :ok
    else
      # IO.puts("Virhe suoritettaessa skriptiä: #{script_path}")
      # IO.puts("Virheilmoitus: #{output}")
      {:error, output}
    end
  end

  defp send_progress(state, message) do
    message = {:pipeline_message, state.execution_id, message}
    Phoenix.PubSub.broadcast(@pubsub, "#{@topic}:*", message)
    Phoenix.PubSub.broadcast(@pubsub, "#{@topic}:#{state.execution_id}", message)
    %{state | log: state.log ++ [{DateTime.utc_now(), message}]}
  end
end
