[
  {Recorrido, "lib/structs/Recorrido.ex"},
  {Terreno, "lib/structs/Terreno.ex"},
  {Analizador, "lib/Analizador.ex"},
  {Buscador, "lib/Buscador.ex"},
  {CargadorDatos, "lib/CargadorDatos.ex"},
  {ReporteCSV, "lib/GeneradorReporteCSV.ex"},
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
  Punto de entrada general de la aplicación.
  Orquesta la ejecución secuencial entre la auditoría, carga, búsqueda,
  análisis y generación de salidas (CSV, TXT, SVG).
  """

  @doc """
  Ejecuta el flujo completo de la aplicación.
  Soporta rutas personalizadas para los archivos de entrada y salida.
  """
  def ejecutar(
        ruta_bateria \\ Path.join(__DIR__, "data/bateria.txt"),
        ruta_terrenos \\ Path.join(__DIR__, "data/terrenos.csv"),
        ruta_cuadricula \\ Path.join(__DIR__, "data/edificio.txt")
      ) do
    IO.puts("=== INICIANDO SISTEMA DE RESCATE ROBÓTICO ===")
    IO.puts("1. Auditando archivos de entrada...")

    ruta_reporte_validacion = Path.join(__DIR__, "validacion_edificio.txt")

    case ValidadorEdificio.validar_todo(
           ruta_bateria,
           ruta_terrenos,
           ruta_cuadricula,
           ruta_reporte_validacion
         ) do
      :ok ->
        IO.puts("   [OK] Archivos validados correctamente.")

        # 2. Carga
        IO.puts("2. Cargando estructuras de datos...")
        {:ok, datos_juego} =
          CargadorDatos.cargar_todo(ruta_bateria, ruta_terrenos, ruta_cuadricula)

        # 3. Exploración mediante Backtracking
        IO.puts(
          "3. Explorando rutas con backtracking (orden: Arriba, Derecha, Abajo, Izquierda)..."
        )
        recorridos = Buscador.buscar_todos_los_recorridos(datos_juego)

        # 4. Procesamiento de métricas y mínimos
        IO.puts("4. Analizando métricas de consumo y movimientos...")
        resultado_analisis = Analizador.analizar(recorridos)

        # 5. Generación de reportes de salida
        IO.puts("5. Generando reportes de salida...")

        # CSV con el listado completo de rutas
        ReporteCSV.generar(recorridos, Path.join(__DIR__, "recorridos_rescate.csv"))
        IO.puts("   -> Archivo 'recorridos_rescate.csv' generado.")

        # Resumen impreso y en TXT
        ReporteResumen.generar(
          resultado_analisis,
          Path.join(__DIR__, "resumen_rescate.txt")
        )

        IO.puts("   -> Archivo 'resumen_rescate.txt' generado.")

        # Plano SVG (mapa + ruta de menor energía o leyenda)
        GeneradorSVG.generar(
          datos_juego,
          resultado_analisis,
          Path.join(__DIR__, "ruta_optima.svg")
        )

        IO.puts("   -> Gráfico 'ruta_optima.svg' generado.")

        IO.puts("\n=== PROCESO FINALIZADO CON ÉXITO ===")
        :ok

      :error ->
        IO.puts("\n [ERROR] Se encontraron inconsistencias en los archivos de entrada.")
        IO.puts(" Por favor revisa el archivo 'validacion_edificio.txt' para ver el detalle.")
        {:error, :validacion_fallida}
    end
  end
end

Principal.ejecutar()
