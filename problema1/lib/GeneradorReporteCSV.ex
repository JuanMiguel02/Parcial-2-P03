defmodule ReporteCSV do
  @moduledoc """
  Genera un archivo CSV con el detalle de los recorridos encontrados.

  Cada fila incluye el identificador del recorrido, sus movimientos, energía
  consumida y la secuencia de coordenadas.
  """

  @doc """
  Escribe los recorridos en formato CSV separado por punto y coma.

  Crea el directorio de destino si aún no existe. Si `ruta_salida` se omite,
  escribe en `salidas/recorridos_rescate.csv`.

  ## Parámetros

    * `recorridos` - lista de estructuras `%Recorrido{}`.
    * `ruta_salida` - ruta del archivo que se generará.
  """
  def generar(recorridos, ruta_salida \\ "salidas/recorridos_rescate.csv") do
    GestorCarpetas.generar_directorio(ruta_salida)
    cabecera = "id;movimientos;energia;posiciones\n"

    filas =
      recorridos
      |> Stream.with_index(1)
      |> Stream.map(fn {recorrido, indice} -> formatear_fila(indice, recorrido) end)
      |> Enum.join("\n")

      contenido =
        if filas == "" do
          cabecera
        else
          cabecera <> filas <> "\n"
        end

    File.write!(ruta_salida, contenido)
  end

  defp formatear_fila(indice, %Recorrido{posiciones: posiciones, energia: energia} = recorrido) do
    movimientos = Analizador.calcular_movimientos(recorrido)
    posiciones_fmt = formatear_posiciones(posiciones)

    "#{indice};#{movimientos};#{energia};#{posiciones_fmt}"
  end

  defp formatear_posiciones(posiciones) do
    posiciones
    |> Enum.map(fn {f, c} -> "(#{f},#{c})" end)
    |> Enum.join("->")
  end
end
