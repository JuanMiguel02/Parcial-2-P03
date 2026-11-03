defmodule ValidadorADN do
  @moduledoc """
  Módulo encargado de la validación previa de los archivos de muestras y motivos
  utilizando funciones recursivas.
  """

  @doc """
  Valida los archivos de entrada y escribe los errores en la ruta de salida indicada.
  """
  def validar_todo(ruta_muestras, ruta_motivos, ruta_val) do
    motivos_lineas = File.stream!(ruta_motivos)
    |> Stream.with_index(1)
    |> Enum.to_list()
    res_motivos = validar_motivos_rec(motivos_lineas, [])

    muestras_lineas = File.stream!(ruta_muestras)
    |> Stream.with_index(1)
    |> Enum.to_list()
    res_muestras = validar_muestras_rec(muestras_lineas, nil, false, [], 0)

    if res_motivos.errores != [] or res_muestras.errores != [] do
      errores_totales = Enum.join(res_motivos.errores ++ res_muestras.errores, "\n")
      File.write!(ruta_val, errores_totales)
      :error
    else
      File.write!(ruta_val, "Sin errores.")
      :ok
    end
  end

  defp validar_motivos_rec([], acc), do: %{errores: acc}
  defp validar_motivos_rec([{linea, num} | resto], acc) do
    texto = String.trim(linea)
    cond do
      texto == "" or String.starts_with?(texto, "#") ->
        validar_motivos_rec(resto, acc)
      not String.match?(texto, ~r/^[ACGT]+$/i) ->
        err = "Línea #{num}: Motivo contiene caracteres inválidos (#{texto})"
        validar_motivos_rec(resto, [err | acc])
      true ->
        validar_motivos_rec(resto, acc)
    end
  end

  defp validar_muestras_rec([], _muestra_actual, _tiene_datos, acc, _n_linea), do: %{errores: acc}
  defp validar_muestras_rec([{linea, num} | resto], muestra_actual, tiene_datos, acc, _n_linea) do
    texto = String.trim(linea)
    cond do
      texto == "" or String.starts_with?(texto, "#") ->
        validar_muestras_rec(resto, muestra_actual, tiene_datos, acc, num)

      String.starts_with?(texto, ">") ->
        id_muestra = String.trim_leading(texto, ">")
        |> String.trim()
        if id_muestra == "" do
          err = "Línea #{num}: Identificador de muestra vacío."
          validar_muestras_rec(resto, nil, false, [err | acc], num)
        else
          validar_muestras_rec(resto, id_muestra, false, acc, num)
        end

      true ->
        if is_nil(muestra_actual) do
          err = "Línea #{num}: Datos de secuencia antes del primer encabezado."
          validar_muestras_rec(resto, muestra_actual, tiene_datos, [err | acc], num)
        else
          if not String.match?(texto, ~r/^[ACGT]+$/i) do
            err = "Línea #{num} (Muestra #{muestra_actual}): Secuencia con caracteres inválidos."
            validar_muestras_rec(resto, muestra_actual, true, [err | acc], num)
          else
            validar_muestras_rec(resto, muestra_actual, true, acc, num)
          end
        end
    end
  end
end
