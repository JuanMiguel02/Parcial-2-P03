defmodule Terreno do
  @enforce_keys [:simbolo, :nombre, :transitable, :costo]
  defstruct [:simbolo, :nombre, :transitable, :costo]

  @doc """
  Construye un %Terreno{} a partir de una línea en formato CSV ("simbolo,nombre,transitable,costo").
  """
  def crear_desde_linea_csv(linea_csv) do
    case String.split(linea_csv, ",", trim: true) do
      [simbolo, nombre, transitable_str, costo_str] ->
        %Terreno{
          simbolo: String.trim(simbolo),
          nombre: String.trim(nombre),
          transitable: String.trim(transitable_str) == "si",
          costo: String.to_integer(String.trim(costo_str))
        }

      _ -> {:error, :formato_csv_invalido}
    end
  end

  @doc """
  Constructores directos para terrenos por defecto.
  """
  def inicio, do: %Terreno{simbolo: "S", nombre: "inicio", transitable: true, costo: 0}
  def meta, do: %Terreno{simbolo: "M", nombre: "meta", transitable: true, costo: 1}
end
