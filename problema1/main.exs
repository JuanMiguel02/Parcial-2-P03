[
  {Recorrido, "lib/structs/Recorrido.ex"},
  {Terreno, "lib/structs/Terreno.ex"},
  {GestorCarpetas, "lib/GestorCarpetas.ex"},
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
  @carpeta_salida "salidas"
  @moduledoc """
  Punto de entrada general de la aplicación.
  Orquesta la ejecución secuencial entre la auditoría, carga, búsqueda,
  análisis y generación de salidas (CSV, TXT, SVG).
  """

  @doc """
  Ejecuta el flujo completo de la aplicación.
  Soporta rutas personalizadas para los archivos de entrada y salida.
  """
  def main(
        ruta_bateria \\ Path.join(__DIR__, "data/bateria.txt"),
        ruta_terrenos \\ Path.join(__DIR__, "data/terrenos.csv"),
        ruta_cuadricula \\ Path.join(__DIR__, "data/edificio.txt")
      ) do
    # Ajustamos las rutas de los reportes
    ruta_val = Path.join([__DIR__, @carpeta_salida, "validacion_edificio.txt"])
    ruta_csv = Path.join([__DIR__, @carpeta_salida, "recorridos_rescate.csv"])
    ruta_txt = Path.join([__DIR__, @carpeta_salida, "resumen_rescate.txt"])
    ruta_svg = Path.join([__DIR__, @carpeta_salida, "ruta_optima.svg"])

    IO.puts("=== INICIANDO SISTEMA DE RESCATE ROBÓTICO ===")
    IO.puts("1. Auditando archivos de entrada...")

    GestorCarpetas.generar_directorio(ruta_val)

    case ValidadorEdificio.validar_todo(
           ruta_bateria,
           ruta_terrenos,
           ruta_cuadricula,
           ruta_val
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
        ReporteCSV.generar(recorridos, ruta_csv)
        IO.puts("   -> Archivo 'recorridos_rescate.csv' generado.")

        # Resumen impreso y en TXT
        ReporteResumen.generar( resultado_analisis, ruta_txt)

        IO.puts("   -> Archivo 'resumen_rescate.txt' generado.")

        # Plano SVG (mapa + ruta de menor energía o leyenda)
        GeneradorSVG.generar(datos_juego,resultado_analisis,ruta_svg )

        IO.puts("   -> Gráfico 'ruta_optima.svg' generado.")
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
