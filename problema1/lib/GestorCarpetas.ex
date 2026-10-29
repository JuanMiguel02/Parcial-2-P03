defmodule GestorCarpetas do
  @doc """
  Garantiza que la carpeta de destino exista antes de intentar escribir archivos en ella.
  """
  def generar_directorio(ruta_archivo) do
    directorio = Path.dirname(ruta_archivo)
    File.mkdir_p!(directorio)
  end
end
