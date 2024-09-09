defmodule FilePathManager do
  def get_file_path(file_name) do
    if Application.get_env(:your_app, :test_mode, false) do
      "test_" <> file_name
    else
      file_name
    end
  end
end
