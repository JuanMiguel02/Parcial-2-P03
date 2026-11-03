[
  {Coincidencia, "lib/structs/Coincidencia.ex"},
  {ValidadorADN, "lib/ValidadorADN.ex"},
  {CargadorADN, "lib/CargadorADN.ex"},
  {BuscadorADN, "lib/BuscadorADN.ex"},
  {ReporteADN, "lib/ReporteADN.ex"}
]
|> Enum.each(fn {modulo, archivo} ->
  unless Code.ensure_loaded?(modulo) do
    Code.require_file(Path.join(__DIR__, archivo))
  end
end)

defmodule PrincipalADN do
  @moduledoc """
  Punto de entrada principal para ejecutar la solución del problema de ADN.
  """

  @carpeta_salida "salidas"

  @doc """
  Función principal que coordina la validación, carga, búsqueda y generación de reportes.
  """
  def main(
        ruta_muestras \\ Path.join(__DIR__, "data/muestras"),
        ruta_motivos \\ Path.join(__DIR__, "data/motivos.txt")
      ) do
    File.mkdir_p!(Path.join(__DIR__, @carpeta_salida))

    ruta_val = Path.join([__DIR__, @carpeta_salida, "validacion_adn.txt"])
    ruta_csv = Path.join([__DIR__, @carpeta_salida, "coincidencias_adn.csv"])
    ruta_txt = Path.join([__DIR__, @carpeta_salida, "resumen_adn.txt"])

    IO.puts("=== INICIANDO BÚSQUEDA DE MOTIVOS DE ADN ===")
    IO.puts("1. Auditando archivos de entrada...")

    case ValidadorADN.validar_todo(ruta_muestras, ruta_motivos, ruta_val) do
      :ok ->
        IO.puts("   [OK] Archivos validados correctamente.")

        IO.puts("2. Cargando estructuras de datos...")
        {:ok, datos} = CargadorADN.cargar_todo(ruta_muestras, ruta_motivos)
        {muestras_map, motivos_lista} = datos

        IO.puts("3. Buscando coincidencias (0 o 1 error, hebra directa y reversa)...")
        coincidencias = BuscadorADN.buscar_coincidencias(datos)

        IO.puts("4. Generando reportes de salida...")
        ReporteADN.generar_csv(coincidencias, ruta_csv)
        IO.puts("   -> Archivo 'coincidencias_adn.csv' generado.")

        ReporteADN.generar_resumen(muestras_map, motivos_lista, coincidencias, ruta_txt)
        IO.puts("   -> Archivo 'resumen_adn.txt' generado.")

        IO.puts("\n=== PROCESO FINALIZADO CON ÉXITO ===")
        :ok

      :error ->
        IO.puts("\n[ERROR] Se encontraron inconsistencias en los archivos de entrada.")
        IO.puts("Por favor revise el archivo 'salidas/validacion_adn.txt'.")
        {:error, :validacion_fallida}
    end
  end
end

PrincipalADN.main()
