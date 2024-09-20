defmodule DocumentPipeline.Client do
  @timeout_seconds 600
  def start_pipeline do
    # Käynnistetään GenServer DynamicSupervisorin kautta
    {:ok, pid} = DocumentPipeline.DynamicSupervisor.start_child()

    # Aloitetaan pipeline-suoritus ja välitetään oma pid
    DocumentPipeline.Server.run_pipeline(pid)

    # Kuunnellaan väliaikatietoja
    listen_for_progress()
  end

  defp listen_for_progress do
    receive do
      {:script_started, script} ->
        IO.puts("Skripti aloitettu: #{script}")
        listen_for_progress()

      {:script_finished, script} ->
        IO.puts("Skripti suoritettu: #{script}")
        listen_for_progress()

      {:script_failed, script, reason} ->
        IO.puts("Skripti epäonnistui: #{script}")
        IO.puts("Syy: #{reason}")
        # Päätetään kuuntelu virheen sattuessa
        :ok

      {:pipeline_failed, reason} ->
        IO.puts("Pipeline epäonnistui: #{reason}")
        :ok

      :pipeline_finished ->
        IO.puts("Pipeline suoritettu loppuun.")
        :ok
    after
      @timeout_seconds * 1000 ->
        IO.puts("Ei saatu päivityksiä #{@timeout_seconds} sekuntiin, lopetetaan.")
        :ok
    end
  end
end
