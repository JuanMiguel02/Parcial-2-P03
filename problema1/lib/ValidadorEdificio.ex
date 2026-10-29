defmodule ValidadorEdificio do
  def validar_todo(ruta_bateria, ruta_terrenos, ruta_cuadricula, ruta_reporte) do
    resultado_bateria = validar_bateria(ruta_bateria)
    resultado_terrenos = validar_terrenos(ruta_terrenos)

    resultado_cuadricula =
      case resultado_terrenos do
        {:ok, simbolos} -> validar_cuadricula(ruta_cuadricula, simbolos)
        {:error, _errores} -> {:error, []}
      end

    todos_los_errores =
      obtener_errores(resultado_bateria) ++
        obtener_errores(resultado_terrenos) ++
        obtener_errores(resultado_cuadricula)

    if todos_los_errores == [] do
      :ok
    else
      escribir_reporte(ruta_reporte, todos_los_errores)
      :error
    end
  end

  defp obtener_errores({:ok, _resultado}), do: []
  defp obtener_errores({:error, lista_errores}), do: lista_errores

  # ===================================================================
  # 1. Validación de Batería (bateria.txt)
  # ===================================================================
  defp validar_bateria(ruta) do
    if File.exists?(ruta) do
      linea =
        File.stream!(ruta)
        |> Stream.with_index(1)
        |> Stream.map(fn {linea, indice} -> {String.trim(linea), indice} end)
        |> Stream.reject(&comentario_o_vacia?/1)
        |> Enum.take(1)

      case linea do
        [{valor_str, num_linea}] ->
          case Integer.parse(valor_str) do
            {val, ""} when val > 0 ->
              {:ok, val}

            _ ->
              error =
                "#{ruta}: (Línea #{num_linea}): B debe ser un único entero positivo (obtenido: '#{valor_str}'). "

              {:error, [error]}
          end

        [] ->
          {:error, ["#{ruta}: El archivo está vacío o no contiene un valor para B."]}
      end
    else
      {:error, ["#{ruta}: El archivo no existe."]}
    end
  end

  # ===================================================================
  # 2. Validación de Terrenos (terrenos.csv)
  # ===================================================================

  defp validar_terrenos(ruta) do
    if File.exists?(ruta) do
      terrenos_stream =
        File.stream!(ruta)
        |> Stream.with_index(1)
        |> Stream.map(fn {linea, indice} -> {String.trim_trailing(linea, "\r\n"), indice} end)
        |> Stream.reject(&comentario_o_vacia?/1)

      lineas = Enum.to_list(terrenos_stream)

      lineas_datos =
        case lineas do
          [{cabecera, _} | resto] ->
            if String.downcase(cabecera) =~ "simbolo" do
              resto
            else
              lineas
            end

          [] ->
            []
        end

      validar_terrenos_rec(lineas_datos, MapSet.new(), _errores_acumulados = [])
    else
      {:error, ["#{ruta}: El archivo no existe."]}
    end
  end

  defp validar_terrenos_rec([], simbolos, errores) do
    if errores == [] do
      {:ok, simbolos}
    else
      {:error, Enum.reverse(errores)}
    end
  end

  defp validar_terrenos_rec([{linea, num_linea} | resto], simbolos, errores) do
    case String.split(linea, ",", trim: true) do
      [simbolo | _resto_columnas] ->
        simbolo = String.trim(simbolo)

        if MapSet.member?(simbolos, simbolo) do
          error = "terrenos.csv: (Línea #{num_linea}): Símbolo repetido '#{simbolo}'."
          validar_terrenos_rec(resto, simbolos, [error | errores])
        else
          validar_terrenos_rec(resto, MapSet.put(simbolos, simbolo), errores)
        end

      _ ->
        error_formato = "terrenos.csv (Línea #{num_linea}): Formato de fila inválido."
        validar_terrenos_rec(resto, simbolos, [error_formato | errores])
    end
  end

  # ===================================================================
  # 3. Validación de Cuadrícula (cuadricula.txt / edificio.txt)
  # ===================================================================

  defp validar_cuadricula(ruta, simbolos_permitidos) do
    if File.exists?(ruta) do
      todos_simbolos =
        simbolos_permitidos
        |> MapSet.put("S")
        |> MapSet.put("M")
        |> MapSet.put("X")

      cuadricula_stream =
        File.stream!(ruta)
        |> Stream.with_index(1)
        |> Stream.map(fn {linea, indice} -> {String.trim_trailing(linea, "\r\n"), indice} end)
        |> Stream.reject(&comentario_o_vacia?/1)

      lineas_filtradas = Enum.to_list(cuadricula_stream)

      if lineas_filtradas == [] do
        {:error, ["Cuadrícula: El archivo está vacío o no contiene filas válidas."]}
      else
        validar_lineas_rec(lineas_filtradas, nil, %{s: 0, m: 0}, todos_simbolos, [])
      end
    else
      {:error, ["Cuadrícula: El archivo no existe."]}
    end
  end

  defp validar_lineas_rec([], _ancho, %{s: s, m: m}, _simbolos, errores) do
    errores =
      if s != 1,
        do: [
          "Cuadrícula General: Debe haber exactamente un punto 'S' (encontrados: #{s})." | errores
        ],
        else: errores

    errores =
      if m != 1,
        do: [
          "Cuadrícula General: Debe haber exactamente un punto 'M' (encontrados: #{m})." | errores
        ],
        else: errores

    if errores == [] do
      {:ok, :validado}
    else
      {:error, Enum.reverse(errores)}
    end
  end

  defp validar_lineas_rec([{linea, num_linea} | resto], ancho_esperado, conteo, simbolos, errores) do
    linea_limpia = String.trim_leading(linea)

    if String.starts_with?(linea_limpia, ">") do
      validar_lineas_rec(resto, ancho_esperado, conteo, simbolos, errores)
    else
      simbolos_fila = String.split(linea, ~r/\s+/, trim: true)
      ancho_actual = length(simbolos_fila)
      es_primera_o_ultima = ancho_esperado == nil or resto == []

      ancho_esperado = ancho_esperado || ancho_actual

      error_ancho =
        if ancho_actual != ancho_esperado do
          [
            "Línea #{num_linea}: La fila no coincide con el ancho de la cuadrícula (esperado #{ancho_esperado} columnas, obtenido #{ancho_actual})."
          ]
        else
          []
        end

      # Se procesa la lista de símbolos puros en validar_celdas_rec
      {nuevo_conteo, err_celdas} =
        validar_celdas_rec(
          simbolos_fila,
          num_linea,
          1,
          es_primera_o_ultima,
          ancho_actual,
          conteo,
          simbolos,
          []
        )

      nuevos_errores = error_ancho ++ err_celdas ++ errores
      validar_lineas_rec(resto, ancho_esperado, nuevo_conteo, simbolos, nuevos_errores)
    end
  end

  # ===================================================================
  # Validación de Celdas (Recursión por Columnas)
  # ===================================================================

  defp validar_celdas_rec(
         _simbolos_restantes = [],
         _linea_fisica,
         _columna_actual,
         _es_fila_borde?,
         _total_columnas,
         conteo_puntos_clave,
         _simbolos_permitidos,
         errores_acumulados
       ) do
    {conteo_puntos_clave, errores_acumulados}
  end

  defp validar_celdas_rec(
         [simbolo_actual | resto_simbolos],
         linea_fisica,
         columna_actual,
         es_fila_borde?,
         total_columnas,
         conteo_puntos_clave,
         simbolos_permitidos,
         errores_acumulados
       ) do
    # Identificación clara de la posición en el contorno
    es_columna_borde? = columna_actual == 1 or columna_actual == total_columnas
    es_posicion_borde? = es_fila_borde? or es_columna_borde?

    # Regla 1: Todo el borde exterior debe ser estrictamente 'X'
    error_borde =
      if es_posicion_borde? and simbolo_actual != "X" do
        [
          "Coordenada (#{linea_fisica}, #{columna_actual}): El borde exterior debe ser 'X' (encontrado '#{simbolo_actual}')."
        ]
      else
        []
      end

    # Regla 2: El símbolo debe pertenecer al catálogo de terrenos.csv o a los especiales (S, M, X)
    error_simbolo =
      if not MapSet.member?(simbolos_permitidos, simbolo_actual) do
        [
          "Coordenada (#{linea_fisica}, #{columna_actual}): El símbolo '#{simbolo_actual}' no está definido en terrenos.csv."
        ]
      else
        []
      end

    # Actualización del conteo de puntos S (inicio) y M (meta)
    nuevo_conteo = actualizar_conteo_puntos(conteo_puntos_clave, simbolo_actual)

    # Colectamos los errores de esta celda
    nuevos_errores = error_borde ++ error_simbolo ++ errores_acumulados

    # Siguiente columna en la fila
    validar_celdas_rec(
      resto_simbolos,
      linea_fisica,
      columna_actual + 1,
      es_fila_borde?,
      total_columnas,
      nuevo_conteo,
      simbolos_permitidos,
      nuevos_errores
    )
  end

  # Función auxiliar para hacer explícito el incremento de 'S' y 'M'
  defp actualizar_conteo_puntos(conteo, "S"), do: %{conteo | s: conteo.s + 1}
  defp actualizar_conteo_puntos(conteo, "M"), do: %{conteo | m: conteo.m + 1}
  defp actualizar_conteo_puntos(conteo, _otro_simbolo), do: conteo

  defp comentario_o_vacia?({linea, _indice}) do
    linea_limpia = String.trim_leading(linea)
    linea_limpia == "" or String.starts_with?(linea_limpia, "#")
  end

  defp escribir_reporte(ruta_salida, errores) do
    GestorCarpetas.generar_directorio(ruta_salida)
    contenido = Enum.join(errores, "\n")
    File.write!(ruta_salida, contenido)
  end
end
