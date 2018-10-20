defmodule Vampyre.Debug do
  def debug?() do
    Application.get_env(:vampyre, :debug, false)
  end

  defp compiled_template_path_as_code(path) do
    Path.join("_vampyre/debug/templates/code", path) <> ".exs"
  end

  defp compiled_template_dir_as_code(path) do
    Path.dirname(compiled_template_path_as_code(path))
  end

  defp compiled_template_path_as_quoted(path) do
    Path.join("_vampyre/debug/templates/quoted", path) <> ".exs"
  end

  defp compiled_template_dir_as_quoted(path) do
    Path.dirname(compiled_template_path_as_quoted(path))
  end

  defp compiled_template_path_as_segments(path) do
    Path.join("_vampyre/debug/templates/segments", path) <> ".exs"
  end

  defp compiled_template_dir_as_segments(path) do
    Path.dirname(compiled_template_path_as_segments(path))
  end

  def dump_compiled_template_as_segments(path, segments) do
    dst_dir = compiled_template_dir_as_segments(path)
    dst_path = compiled_template_path_as_segments(path)
    File.mkdir_p!(dst_dir)

    contents =
      segments
      |> inspect()
      |> Code.format_string!()

    File.write!(dst_path, contents)
  end

  def dump_compiled_template_as_quoted_expression(path, quoted) do
    dst_dir = compiled_template_dir_as_quoted(path)
    dst_path = compiled_template_path_as_quoted(path)
    File.mkdir_p!(dst_dir)

    contents =
      quoted
      |> inspect()
      |> Code.format_string!()

    File.write!(dst_path, contents)
  end

  def dump_compiled_template_as_code(path, quoted) do
    dst_dir = compiled_template_dir_as_code(path)
    dst_path = compiled_template_path_as_code(path)
    File.mkdir_p!(dst_dir)

    contents =
      quoted
      |> Macro.to_string()
      |> Code.format_string!()

    File.write!(dst_path, contents)
  end
end
