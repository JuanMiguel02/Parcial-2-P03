[
  {Recorrido, "lib/structs/Recorrido.ex"},
  {Terreno, "lib/structs/Terreno.ex"},
  {GestorCarpetas, "lib/GestorCarpetas.ex"},
  {Analizador, "lib/Analizador.ex"},
  {Buscador, "lib/Buscador.ex"},
  {CargadorDatos, "lib/CargadorDatos.ex"},
  {ExpansionEnergia, "lib/ExpansionEnergia.ex"},
  {ReporteCSV, "lib/GeneradorReporteCSV.ex"},
  {ReporteExpansion, "lib/GeneradorReporteExpansion.ex"},
  {ReporteResumen, "lib/GeneradorReporteResumen.ex"},
  {GeneradorSVG, "lib/GeneradorSVG.ex"},
  {ValidadorEdificio, "lib/ValidadorEdificio.ex"}
]
|> Enum.each(fn {modulo, archivo} ->
  unless Code.ensure_loaded?(modulo) do
    Code.require_file(Path.join(__DIR__, archivo))
  end
end)

defmodule Principal do
  @moduledoc """
  Punto de entrada de la aplicación de recorridos del problema 1.

  Orquesta la validación y carga de datos, la búsqueda y el análisis de rutas,
  y la generación de los reportes CSV, TXT y SVG en la carpeta `salidas`.
  """

  @carpeta_salida "salidas"

  @doc """
  Ejecuta el flujo completo de la aplicación.

  Los argumentos permiten indicar rutas alternativas para los archivos de
  entrada; si se omiten, se usan los archivos de `problema1/data`. Los reportes
  se escriben en la carpeta `salidas` junto al script.

  Devuelve `:ok` si la validación y el procesamiento terminan correctamente, o
  `{:error, :validacion_fallida}` si los archivos no pasan la validación. Los
  errores de lectura o escritura del sistema de archivos se propagan.

  ## Parámetros

    * `ruta_bateria` - ruta al archivo con el presupuesto de batería.
    * `ruta_terrenos` - ruta al catálogo CSV de terrenos.
    * `ruta_cuadricula` - ruta al archivo de la cuadrícula.
  """
  def main(
        ruta_bateria \\ Path.join(__DIR__, "data/bateria.txt"),
        ruta_terrenos \\ Path.join(__DIR__, "data/terrenos.csv"),
        ruta_cuadricula \\ Path.join(__DIR__, "data/edificio.txt")
      ) do
    # Ajustamos las rutas de los reportes
    ruta_val = Path.join([__DIR__, @carpeta_salida, "validacion_edificio.txt"])
    ruta_exp = Path.join([__DIR__, @carpeta_salida, "expansion_energia.txt"])
    ruta_csv = Path.join([__DIR__, @carpeta_salida, "recorridos_rescate.csv"])
    ruta_txt = Path.join([__DIR__, @carpeta_salida, "resumen_rescate.txt"])
    ruta_svg = Path.join([__DIR__, @carpeta_salida, "ruta_optima.svg"])

    IO.puts("=== INICIANDO SISTEMA DEL ROBOT DE RESCATE ===\n")
    IO.puts("1. Validando archivos de entrada...\n")

    GestorCarpetas.generar_directorio(ruta_val)

    case ValidadorEdificio.validar_todo(
           ruta_bateria,
           ruta_terrenos,
           ruta_cuadricula,
           ruta_val
         ) do
      :ok ->
        IO.puts("   [OK] Archivos validados correctamente.\n")

        # 2. Carga
        IO.puts("2. Cargando datos...\n")
        {:ok, datos_juego} =
          CargadorDatos.cargar_todo(ruta_bateria, ruta_terrenos, ruta_cuadricula)

        IO.puts("2b. Generando Stream de expansión de energía y verificando alcanzabilidad... \n")
        resultado_expansion =
          ReporteExpansion.procesar_y_reportar(
            datos_juego.mapa,
            datos_juego.inicio,
            datos_juego.meta,
            datos_juego.bateria,
            ruta_exp)

          IO.puts("   -> Archivo 'expansion_energia.txt' generado.\n")

        case resultado_expansion do
          {:ok, _estado_final} ->
            # 3. Exploración mediante Backtracking
        IO.puts(
          "3. Explorando rutas con backtracking (orden: Arriba, Derecha, Abajo, Izquierda)...\n"
        )
        recorridos = Buscador.buscar_todos_los_recorridos(datos_juego)

        # 4. Procesamiento de métricas y mínimos
        IO.puts("4. Analizando métricas de consumo y movimientos...\n")
        resultado_analisis = Analizador.analizar(recorridos)

        # 5. Generación de reportes de salida
        IO.puts("5. Generando reportes de salida...\n")

        # CSV con el listado completo de rutas
        ReporteCSV.generar(recorridos, ruta_csv)
        IO.puts("   -> Archivo 'recorridos_rescate.csv' generado.\n")

        # Resumen impreso y en TXT
        ReporteResumen.generar(resultado_analisis, ruta_txt)

        IO.puts("   -> Archivo 'resumen_rescate.txt' generado.\n")

        # Plano SVG (mapa + ruta de menor energía o leyenda)
        GeneradorSVG.generar(datos_juego, resultado_analisis, ruta_svg)

        IO.puts("   -> Gráfico 'ruta_optima.svg' generado.\n")

        {:error, :meta_inalcanzable} ->
          # OMITIR enumeración recursiva
          IO.puts("   [AVISO] La meta NO es alcanzable dentro del límite de batería B.\n")
          IO.puts("   -> Omitiendo la enumeración recursiva de rutas.\n")

          # Generar solo el gráfico SVG con la leyenda "sin recorrido"
          GeneradorSVG.generar(datos_juego, {:error, :sin_recorridos}, ruta_svg)
          IO.puts("   -> Gráfico 'ruta_optima.svg' (con leyenda 'sin recorrido') generado.\n")
        end


        IO.puts("\nArchivos generados con éxito en la carpeta '#{@carpeta_salida}/'.")
        IO.puts("\n=== PROCESO FINALIZADO CON ÉXITO ===")
        :ok

      :error ->
        IO.puts("\n [ERROR] Se encontraron inconsistencias en los archivos de entrada.")
        IO.puts(" Por favor revise el archivo 'validacion_edificio.txt' para ver el detalle.")
        {:error, :validacion_fallida}
    end
  end
end

Principal.main()
