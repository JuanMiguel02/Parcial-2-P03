defmodule GestorCarpetas do
  @moduledoc """
  Proporciona utilidades para preparar directorios de archivos de salida.
  """

  @doc """
  Crea el directorio padre de una ruta de archivo, incluidos sus padres.

  Devuelve `:ok` cuando el directorio existe o se pudo crear. Propaga como
  excepción los errores de sistema de archivos.

  ## Parámetros

    * `ruta_archivo` - ruta del archivo cuyo directorio padre se necesita.
  """
  def generar_directorio(ruta_archivo) do
    directorio = Path.dirname(ruta_archivo)
    File.mkdir_p!(directorio)
  end
end
