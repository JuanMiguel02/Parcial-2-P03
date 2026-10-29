defmodule CargadorDatos do
  @moduledoc """
  Carga los archivos de batería, catálogo de terrenos y cuadrícula.

  Convierte sus contenidos en un mapa de datos listo para `Buscador`, con el
  presupuesto de batería, el catálogo de `%Terreno{}`, la cuadrícula indexada
  por coordenadas y las posiciones de inicio y meta.
  """

  @doc """
  Carga y combina los datos de entrada de la aplicación.

  Devuelve `{:ok, datos}`, donde `datos` contiene las claves `:bateria`,
  `:catalogo`, `:mapa`, `:inicio` y `:meta`.

  ## Parámetros

    * `ruta_bateria` - ruta al archivo con el presupuesto de batería.
    * `ruta_terrenos` - ruta al catálogo CSV de terrenos.
    * `ruta_cuadricula` - ruta al archivo de la cuadrícula.

  Se espera que los archivos hayan sido validados previamente. Los errores de
  lectura o conversión se propagan como excepciones de las funciones utilizadas
  para procesarlos.
  """
  def cargar_todo(ruta_bateria, ruta_terrenos, ruta_cuadricula) do
    presupuesto_bateria = cargar_bateria(ruta_bateria)
    terrenos = cargar_terrenos(ruta_terrenos)

    {mapa_coordenadas, pos_inicio, pos_meta} =
      cargar_cuadricula(ruta_cuadricula, terrenos)

    {:ok,
     %{
       bateria: presupuesto_bateria,
       catalogo: terrenos,
       mapa: mapa_coordenadas,
       inicio: pos_inicio,
       meta: pos_meta
     }}
  end

  defp cargar_bateria(ruta_archivo) do
    File.stream!(ruta_archivo)
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, indice} -> {String.trim(linea), indice} end)
    |> Stream.reject(&linea_vacia_o_comentario?/1)
    |> Enum.take(1)
    |> case do
      [{valor_texto, _linea}] ->
        String.to_integer(valor_texto)
    end
  end

  defp cargar_terrenos(ruta_archivo) do
    terrenos_base =
      File.stream!(ruta_archivo)
      |> Stream.with_index(1)
      |> Stream.map(fn {linea, indice} -> {String.trim(linea), indice} end)
      |> Stream.reject(fn {linea, _indice} ->
        String.downcase(linea) =~ "simbolo"
      end)
      |> Enum.reduce(%{}, fn {linea, _indice}, acumulador ->
        terreno = Terreno.crear_desde_linea_csv(linea)
        Map.put(acumulador, terreno.simbolo, terreno)
      end)

      terrenos_base
    |> Map.put_new("S", Terreno.inicio())
    |> Map.put_new("M", Terreno.meta())
  end

  defp cargar_cuadricula(ruta_archivo, terrenos) do
    stream_lineas =
      File.stream!(ruta_archivo)
      |> Stream.with_index(1)
      |> Stream.map(fn {linea, idx} -> {String.trim_trailing(linea, "\r\n"), idx} end)
      |> Stream.reject(&linea_vacia_o_comentario?/1)

      procesar_filas_recursivo(
        Enum.to_list(stream_lineas),
        terrenos,
        _mapa_acumulado = %{},
        _pos_inicio = nil,
        _pos_mea = nil
      )
  end

  defp procesar_filas_recursivo([], _terrenos, mapa_acumulado, pos_inicio, pos_meta) do
    {mapa_acumulado, pos_inicio, pos_meta}
  end

  defp procesar_filas_recursivo(
         [{contenido_linea, numero_linea_fisica} | resto_filas],
         terrenos,
         mapa_acumulado,
         pos_inicio,
         pos_meta
       ) do
    linea_limpia = String.trim_leading(contenido_linea)

    if String.starts_with?(linea_limpia, ">") do
      procesar_filas_recursivo(resto_filas, terrenos, mapa_acumulado, pos_inicio, pos_meta)
    else
      simbolos_fila = String.split(contenido_linea, ~r/\s+/, trim: true)

      {nuevo_mapa, nuevo_inicio, nueva_meta} =
        procesar_columnas_recursivo(
          simbolos_fila,
          numero_linea_fisica,
          _columna_inicial = 1,
          terrenos,
          mapa_acumulado,
          pos_inicio,
          pos_meta
        )

      procesar_filas_recursivo(resto_filas, terrenos, nuevo_mapa, nuevo_inicio, nueva_meta)
    end
  end

  defp procesar_columnas_recursivo(
         _simbolos_restantes = [],
         _linea_fisica,
         _columna_actual,
         _catalogo,
         mapa_acumulado,
         pos_inicio,
         pos_meta
       ) do
    {mapa_acumulado, pos_inicio, pos_meta}
  end

  defp procesar_columnas_recursivo(
         [simbolo_actual | resto_simbolos],
         linea_fisica,
         columna_actual,
         terrenos,
         mapa_acumulado,
         pos_inicio,
         pos_meta
       ) do
    coordenada_actual = {linea_fisica, columna_actual}
    terreno = Map.get(terrenos, simbolo_actual)

    mapa_actualizado = Map.put(mapa_acumulado, coordenada_actual, terreno)

    nuevo_inicio = if simbolo_actual == "S", do: coordenada_actual, else: pos_inicio
    nueva_meta = if simbolo_actual == "M", do: coordenada_actual, else: pos_meta

    procesar_columnas_recursivo(
      resto_simbolos,
      linea_fisica,
      columna_actual + 1,
      terrenos,
      mapa_actualizado,
      nuevo_inicio,
      nueva_meta
    )
  end

  defp linea_vacia_o_comentario?({contenido, _idx}) do
    linea_limpia = String.trim_leading(contenido)
    linea_limpia == "" or String.starts_with?(linea_limpia, "#")
  end
end
