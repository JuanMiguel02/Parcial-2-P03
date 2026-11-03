defmodule ReporteExpansion do
  @moduledoc """
  Consume la expansión de energía, genera un reporte de sus estados y verifica
  si una posición meta es alcanzable dentro del presupuesto de batería.
  """

  @doc """
  Genera el reporte de expansión y comprueba la alcanzabilidad de la meta.

  El reporte incluye cada estado distinto desde el inicial hasta el estado
  estable y se escribe en `ruta_salida`. La meta se considera alcanzable si
  aparece en el estado final con un costo menor o igual a `bateria`.

  ## Parámetros

    * `mapa` - mapa de coordenadas `{fila, columna}` a terrenos transitables o
      no transitables.
    * `pos_inicio` - coordenada inicial de la expansión.
    * `pos_meta` - coordenada cuya alcanzabilidad se verifica.
    * `bateria` - costo máximo permitido para alcanzar una casilla.
    * `ruta_salida` - ruta del archivo de texto que se generará.

  ## Devuelve

    * `{:ok, estado_final}` si la meta es alcanzable.
    * `{:error, :meta_inalcanzable}` si no se alcanza con la batería disponible.

  Los errores de escritura del archivo se propagan mediante `File.write!/2`.
  """
  def procesar_y_reportar(mapa, pos_inicio, pos_meta, bateria, ruta_salida) do
    stream = ExpansionEnergia.generar_stream(mapa, pos_inicio, bateria)

    pasos_distintos = consumir_hasta_estabilizacion(stream)
    indice_estabilizacion = max(0, length(pasos_distintos) - 1)
    estado_final = List.last(pasos_distintos)

    contenido_txt = formatear_reporte(pasos_distintos, indice_estabilizacion)
    File.write!(ruta_salida, contenido_txt)

    meta_alcanzable? = Map.has_key?(estado_final, pos_meta) and Map.get(estado_final, pos_meta) <= bateria

    if meta_alcanzable? do
      {:ok, estado_final}
    else
      {:error, :meta_inalcanzable}
    end
  end

  defp consumir_hasta_estabilizacion(stream) do
    # Se detiene ante el primer estado repetido; este indica que no hubo nuevas
    # casillas ni mejoras de costo en la iteración.
    stream
    |> Enum.reduce_while({[], nil}, fn estado_actual, {pasos_acumulados, estado_previo} ->
      if estado_actual == estado_previo do
        # Al halt, INVERTIMOS la lista porque fuimos agregando a la cabeza [nuevo | lista]
        {:halt, Enum.reverse(pasos_acumulados)}
      else
        # Agregamos la foto actual a la cabeza
        {:cont, {[estado_actual | pasos_acumulados], estado_actual}}
      end
  end)
  |> case do
    # Si retornó la lista por :halt (ya viene invertida en orden correcto Paso 0 -> Paso N)
    pasos when is_list(pasos) -> pasos
    # Si el stream termina antes de estabilizarse, devolvemos lo acumulado en orden.
    {pasos_rev, _ultimo} -> Enum.reverse(pasos_rev)
  end
  end

  defp formatear_reporte(pasos_distintos, indice_estabilizacion) do
    encabezado = "=== PROCESO DE EXPANSION DE ENERGIA ===\n" <>
                 "Indice de estabilizacion: #{indice_estabilizacion}\n\n"

    cuerpo =
      pasos_distintos
      |> Enum.with_index()
      |> Enum.map(fn {estado, paso} ->
        posiciones_ordenadas =
          estado
            |> Map.to_list()
            |> Enum.sort_by(fn {{f, c}, _costo} -> {f, c} end)
            |> Enum.map(fn {{f, c}, costo} -> "({#{f}, #{c}}: #{costo})" end)
            |> Enum.join(", ")

        "Paso #{paso}:\n [#{posiciones_ordenadas}]\n"
      end)
      |> Enum.join("\n")

    encabezado <> cuerpo
  end
end
