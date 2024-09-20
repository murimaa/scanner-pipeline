defmodule DocumentPipeline.Client do
  import IO.ANSI

  @spinner_frames ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
  @tick_mark "✓"
  @failed_mark "✗"
  def start_pipeline do
    # Käynnistetään GenServer DynamicSupervisorin kautta
    {:ok, pid} = DocumentPipeline.DynamicSupervisor.start_child()

    # Aloitetaan pipeline-suoritus ja välitetään oma pid
    DocumentPipeline.Server.run_pipeline(pid)

    # Kuunnellaan väliaikatietoja
    listen_for_progress()
  end

  defp listen_for_progress do
    listen_for_progress(0, [])
  end

  defp listen_for_progress(spinner_index, status_list) do
    receive do
      {:script_started, script} ->
        new_status_list = [{script, :started}] ++ status_list
        update_status(get_spinner_char(spinner_index), status_list, new_status_list)
        listen_for_progress(spinner_index, new_status_list)

      {:script_finished, script} ->
        [_script_prev_status | rest] = status_list
        new_status_list = [{script, :finished}] ++ rest
        update_status(@tick_mark, status_list, new_status_list)
        listen_for_progress(spinner_index, new_status_list)

      {:script_failed, script, reason} ->
        [_script_prev_status | rest] = status_list
        new_status_list = [{script, :failed}] ++ rest
        update_status(@failed_mark, status_list, new_status_list)

        IO.puts("\nScript failed: #{script}")
        IO.puts("Reason: #{reason}")
        :ok

      {:pipeline_failed, reason} ->
        IO.puts("\nPipeline failed: #{reason}")
        :ok

      :pipeline_finished ->
        IO.puts("\nPipeline completed successfully.")
        :ok
    after
      100 ->
        next_index = rem(spinner_index + 1, length(@spinner_frames))

        update_status(get_spinner_char(next_index), status_list)
        listen_for_progress(next_index, status_list)
    end
  end

  defp update_status(progress_char, prev_statuses) do
    update_status(progress_char, prev_statuses, prev_statuses)
  end

  defp update_status(progress_char, prev_statuses, new_statuses) do
    new_line? = length(new_statuses) > length(prev_statuses)
    if new_line?, do: IO.write("\n")

    colored_progress_char = color_progress_char(progress_char)
    status_text = format_status(new_statuses)

    # Clear the entire line and move cursor to the beginning
    IO.write("\r#{clear_line()}")

    # Write the new status
    IO.write("#{colored_progress_char} #{status_text}")
  end

  defp color_progress_char(char) do
    get_progress_color(char) <> char <> reset()
  end

  defp format_status(status_list) do
    {text, status} = hd(status_list)
    status_color = get_status_color(status)
    "#{text}: #{status_color}#{status}#{reset()}"
  end

  defp get_progress_color(char) do
    case char do
      @tick_mark -> green()
      @failed_mark -> red()
      # spinner characters
      _ -> yellow()
    end
  end

  defp get_status_color(status) do
    case status do
      :started -> yellow()
      :finished -> green()
      _ -> red()
    end
  end

  defp get_spinner_char(spinner_index), do: Enum.at(@spinner_frames, spinner_index)
end
