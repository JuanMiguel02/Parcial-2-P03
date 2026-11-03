defmodule ReporteADN do
  @moduledoc """
  Módulo para generar los reportes de salida en formato CSV y TXT.
  """

  @doc """
  Escribe el archivo CSV con las coincidencias encontradas.
  """
  def generar_csv(coincidencias, ruta_csv) do
    header = "muestra;motivo;orientacion;inicio;fin;diferencias"
    filas = Enum.map(coincidencias, fn c ->
      "#{c.muestra};#{c.motivo};#{c.orientacion};#{c.inicio};#{c.fin};#{c.diferencias}"
    end)
    File.write!(ruta_csv, Enum.join([header | filas], "\n"))
  end

  @doc """
  Genera el archivo de resumen en texto plano y lo muestra en pantalla.
  """
  def generar_resumen(muestras_map, motivos, coincidencias, ruta_txt) do
    muestras_ids = Map.keys(muestras_map) |> Enum.sort()

    conteo = Enum.reduce(coincidencias, %{}, fn c, acc ->
      Map.update(acc, {c.muestra, c.motivo}, 1, &(&1 + 1))
    end)

    encontrados = Map.keys(conteo) |> Enum.map(fn {_, m} -> m end) |> Enum.uniq()
    no_encontrados = motivos -- encontrados

    lineas_conteo = for m <- muestras_ids, mot <- motivos do
      cant = Map.get(conteo, {m, mot}, 0)
      "Muestra: #{m} | Motivo: #{mot} -> #{cant} coincidencia(s)"
    end

    lineas_no_encontrados = if no_encontrados == [] do
      ["Ninguno."]
    else
      Enum.map(no_encontrados, fn mot -> "- #{mot}" end)
    end

    lineas =
      ["=== RESUMEN DE COINCIDENCIAS ADN ===", "", "[Conteo por Muestra y Motivo]:"] ++
      lineas_conteo ++
      ["", "[Motivos que NO aparecieron]:"] ++
      lineas_no_encontrados

    texto_final = Enum.join(lineas, "\n")
    File.write!(ruta_txt, texto_final)

    IO.puts("\n--- RESUMEN EN PANTALLA ---")
    IO.puts(texto_final)
  end
end
