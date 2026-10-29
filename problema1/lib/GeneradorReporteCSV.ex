defmodule ReporteCSV do
  def generar(recorridos, ruta_salida) do
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
