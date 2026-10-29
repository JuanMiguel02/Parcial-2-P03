defmodule ReporteResuen do
  def generar(resultado_analisis, ruta_salida) do
    contenido = construir_resumen(resultado_analisis)

    IO.puts("\n" <> contenido)

    File.write!(ruta_salida, contenido)
  end

  # ===================================================================
  # Caso 1: No existen recorridos válidos
  # ===================================================================

  defp construir_resumen({:error, :sin_recorridos}) do
    """
    ==================================================
                 RESUMEN DE EXPLORACIÓN
    ==================================================
    Estado: No existe recorrido válido hacia la meta.
    Total de recorridos encontrados: 0
    ==================================================
    """
  end

  # ===================================================================
  # Caso 2: Existen recorridos válidos
  # ===================================================================

  defp construir_resumen({:ok, metricas}) do
    texto_menos_mov = formatear_lista_recorridos(metricas.menos_movimientos)
    texto_menor_energia = formatear_lista_recorridos(metricas.menor_energia)

    """
    ==================================================
                 RESUMEN DE EXPLORACIÓN
    ==================================================
    Total de recorridos encontrados: #{metricas.total}

    --------------------------------------------------
    RECORRIDOS CON MENOS MOVIMIENTOS (#{metricas.movimientos_minimos} pasos)
    --------------------------------------------------
    #{texto_menos_mov}

    --------------------------------------------------
    RECORRIDOS CON MENOR ENERGÍA (#{metricas.energia_minima} unidades)
    --------------------------------------------------
    #{texto_menor_energia}
    ==================================================
    """
  end

  defp formatear_lista_recorridos(recorridos) do
    recorridos
    |> Stream.with_index(1)
    |> Stream.map(fn {recorrido, idx} ->
      movs = Analizador.calcular_movimientos(recorrido)
      pos_fmt = Enum.map_join(recorrido.posiciones, "->", fn {f, c} -> "(#{f},#{c})" end)

      "  [Opción #{idx}] Movimientos: #{movs} | Energía: #{recorrido.energia}\n   Ruta: #{pos_fmt}"
    end)
    |> Enum.join("\n\n")
  end
end
