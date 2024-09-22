defmodule DocumentPipeline.Server do
  use GenServer
  @pubsub DocumentPipeline.PubSub
  @topic "pipeline_messages"

  @tmp_dir Application.compile_env(:document_pipeline, :tmp_path)
  ## Client API

  def start_link({execution_id, scripts_path, input_path, output_path}) do
    GenServer.start_link(__MODULE__, {execution_id, scripts_path, input_path, output_path},
      name: via_tuple(execution_id)
    )
  end

  def child_spec({scripts_path, input_path, output_path}) do
    execution_id = for _ <- 1..20, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

    %{
      id: {__MODULE__, execution_id},
      start: {__MODULE__, :start_link, [{execution_id, scripts_path, input_path, output_path}]},
      restart: :temporary
    }
  end

  ## Server Callbacks

  def init({execution_id, scripts_path, input_path, output_path}) do
    {:ok,
     %{
       execution_id: execution_id,
       scripts_path: scripts_path,
       input_path: input_path,
       output_path: output_path
     }, {:continue, :run_pipeline}}
  end

  def handle_continue(
        :run_pipeline,
        %{execution_id: execution_id} = state
      ) do
    scripts_with_args = get_scripts(state)
    run_scripts(execution_id, scripts_with_args)
    {:noreply, state}
  end

  ## Helper Functions

  defp via_tuple(execution_id) do
    {:via, Registry, {DocumentPipeline.PipelineRegistry, execution_id}}
  end

  defp get_scripts(%{
         execution_id: execution_id,
         scripts_path: scripts_path,
         input_path: input_path,
         output_path: output_path
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
            Path.join([output_path, execution_id])
          else
            # Muut skriptit käyttävät tmp_dir hakemistoa
            Path.join([@tmp_dir, execution_id, script_name])
          end

        # Luodaan tuple {script, args, cwd}
        tuple = {script, prev_cwd, cwd}

        {[tuple | acc], cwd}
      end)

    Enum.reverse(script_tuples)
  end

  defp run_scripts(execution_id, scripts_with_args) do
    send_progress(execution_id, %{event: :pipeline_started})

    Enum.each(scripts_with_args, fn {script, args, cwd} ->
      send_progress(execution_id, %{event: :script_started, script: script})

      case run_script(script, args, cwd) do
        :ok ->
          send_progress(execution_id, %{event: :script_finished, script: script})

        {:error, reason} ->
          send_progress(execution_id, %{event: :script_failed, script: script})
          send_progress(execution_id, %{event: :pipeline_failed})
          # Lopetetaan suorituksen jatkaminen
          exit(reason)
      end
    end)

    send_progress(execution_id, %{event: :pipeline_finished})
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

  defp send_progress(execution_id, message) do
    Phoenix.PubSub.broadcast(@pubsub, @topic, {:pipeline_message, execution_id, message})
  end
end
