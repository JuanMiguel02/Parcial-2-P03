defmodule CargadorADN do
  @moduledoc """
  Módulo para la carga perezosa de los archivos de muestras y motivos mediante streams.
  """

  @doc """
  Carga y procesa los archivos de entrada devolviendo un mapa de muestras y una lista de motivos.
  """
  def cargar_todo(ruta_muestras, ruta_motivos) do
    muestras =
      File.stream!(ruta_muestras)
      |> Stream.map(&String.trim/1)
      |> Enum.reduce({nil, %{}}, fn linea, {actual, acc} ->
        cond do
          linea == "" or String.starts_with?(linea, "#") ->
            {actual, acc}
          String.starts_with?(linea, ">") ->
            id = String.trim_leading(linea, ">") |> String.trim()
            {id, Map.put_new(acc, id, "")}
          true ->
            sec_actual = Map.get(acc, actual, "")
            {actual, Map.put(acc, actual, sec_actual <> String.upcase(linea))}
        end
      end)
      |> elem(1)

    motivos =
      File.stream!(ruta_motivos)
      |> Stream.map(&String.trim/1)
      |> Stream.reject(fn l -> l == "" or String.starts_with?(l, "#") end)
      |> Stream.map(&String.upcase/1)
      |> Enum.to_list()
      |> Enum.uniq()

    {:ok, {muestras, motivos}}
  end
end
