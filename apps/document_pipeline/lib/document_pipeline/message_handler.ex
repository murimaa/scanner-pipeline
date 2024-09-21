defmodule DocumentPipeline.MessageHandler do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_cast({:relay_message, execution_id, message}, state) do
    # Logic to send the message to the appropriate client
    # This could involve WebSockets, Phoenix PubSub, or other mechanisms
    IO.inspect(message, label: "#{execution_id} relayed message")
    {:noreply, state}
  end

  # Client API
  def relay_message(execution_id, message) do
    GenServer.cast(__MODULE__, {:relay_message, execution_id, message})
  end
end
