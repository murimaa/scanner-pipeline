defmodule Web.Config do
  def load do
    config_path = Application.get_env(:document_pipeline, :yaml_config)

    config_path
    |> YamlElixir.read_from_file()
    |> case do
      {:ok, config} -> config
      {:error, reason} -> raise "Failed to load config: #{reason}"
    end
  end

  defp get(key) do
    config = load()
    get_in(config, String.split(key, "."))
  end

  def scan_pipelines() do
    get("pipelines.scan") |> Enum.map(&Map.get(&1, "id"))
  end
end
