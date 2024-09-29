defmodule WebWeb.PipelineController do
  use WebWeb, :controller

  @pipeline_path Application.compile_env(:document_pipeline, :pipeline_path)
  @input_path Application.compile_env(:document_pipeline, :input_path)

  def run(conn, _params) do
    Task.start(fn ->
      {:ok, _pid} =
        DocumentPipeline.DynamicSupervisor.start_child("scan", @input_path)
    end)

    conn
    |> put_status(200)
    |> json(%{})
  end
end
