defmodule DocumentPipeline.Server do
  use GenServer

  @scripts_path Path.absname("scripts")
  @input_path Path.absname("test_input")
  @tmp_dir Path.absname("tmp")
  @output_path Path.absname("test_output")
  ## Client API

  # Käynnistää GenServerin
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, :ok, []]},
      restart: :temporary
    }
  end

  # Julkinen funktio pipeline-suorituksen aloittamiseen
  def run_pipeline(pid) do
    # Välitetään asiakkaan pid GenServerille
    GenServer.cast(pid, {:run_pipeline, self()})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_cast({:run_pipeline, client_pid}, state) do
    execution_id = for _ <- 1..20, into: "", do: <<Enum.random(~c"0123456789abcdef")>>
    scripts_with_args = get_scripts(execution_id)

    # Suoritetaan pipeline suoraan GenServerin sisällä
    run_scripts(scripts_with_args, client_pid)

    {:noreply, state}
  end

  ## Apu-funktiot

  defp get_scripts(execution_id) do
    scripts =
      Path.wildcard(Path.join(@scripts_path, "*.sh"))
      |> Enum.sort()

    # Viimeisen skriptin indeksi
    last_index = length(scripts) - 1

    {script_tuples, _} =
      Enum.reduce(Enum.with_index(scripts), {[], @input_path}, fn {script, index},
                                                                  {acc, prev_cwd} ->
        script_name = script |> Path.rootname() |> Path.basename()

        # Määritellään cwd
        cwd =
          if index == last_index do
            # Viimeisen skriptin cwd output_dir
            Path.join([@output_path, execution_id])
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

  defp get_scripts(execution_id) do
    scripts =
      Path.wildcard(Path.join(@scripts_path, "*.sh"))
      |> Enum.sort()

    {script_tuples, _} =
      Enum.reduce(scripts, {[], @input_path}, fn script, {acc, prev_cwd} ->
        script_name = script |> Path.rootname() |> Path.basename()
        cwd = Path.join([@tmp_dir, execution_id, script_name])

        # Luodaan tuple {script, args, cwd}
        tuple = {script, prev_cwd, cwd}

        {[tuple | acc], cwd}
      end)

    IO.inspect(script_tuples, label: "script_tuples")
    Enum.reverse(script_tuples)
  end

  defp run_scripts(scripts_with_args, client_pid) do
    Enum.each(scripts_with_args, fn {script, args, cwd} ->
      send_progress(client_pid, {:script_started, script})

      case run_script(script, args, cwd) do
        :ok ->
          send_progress(client_pid, {:script_finished, script})

        {:error, reason} ->
          send_progress(client_pid, {:script_failed, script, reason})
          send_progress(client_pid, {:pipeline_failed, reason})
          # Lopetetaan suorituksen jatkaminen
          exit(reason)
      end
    end)

    send_progress(client_pid, :pipeline_finished)
  end

  defp run_script(script_path, args, cwd) do
    IO.puts("Suoritetaan: #{script_path} #{args}")

    File.mkdir_p!(cwd)

    {output, exit_code} =
      if args == nil or args == "" do
        System.cmd("bash", [script_path], cd: cwd)
      else
        System.cmd("bash", [script_path, args], cd: cwd)
      end

    if exit_code == 0 do
      IO.puts("Skripti suoritettu onnistuneesti: #{script_path}")
      :ok
    else
      IO.puts("Virhe suoritettaessa skriptiä: #{script_path}")
      IO.puts("Virheilmoitus: #{output}")
      {:error, output}
    end
  end

  defp send_progress(client_pid, message) do
    send(client_pid, message)
  end
end
