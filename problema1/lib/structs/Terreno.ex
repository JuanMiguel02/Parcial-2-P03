defmodule Terreno do
  @moduledoc """
  Estructura que describe una celda del mapa.

  Un terreno tiene un símbolo, un nombre, una indicación de transitabilidad y
  un costo de energía.
  """

  @enforce_keys [:simbolo, :nombre, :transitable, :costo]
  defstruct [:simbolo, :nombre, :transitable, :costo]

  @typedoc """
  Terreno de la cuadrícula, con su costo de energía por entrada.
  """
  @type t :: %__MODULE__{
          simbolo: String.t(),
          nombre: String.t(),
          transitable: boolean(),
          costo: integer()
        }

  @doc """
  Construye un terreno desde una fila CSV.

  La fila debe tener el formato `simbolo,nombre,transitable,costo`. El valor
  `transitable` es `true` solo si el campo correspondiente es exactamente
  `"si"` después de quitar espacios; otros valores se interpretan como `false`.
  Devuelve `{:error, :formato_csv_invalido}` si la fila no tiene cuatro campos.
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
  Devuelve el terreno transitable que representa la posición inicial.
  """
  def inicio, do: %Terreno{simbolo: "S", nombre: "inicio", transitable: true, costo: 0}

  @doc """
  Devuelve el terreno transitable que representa la posición meta.
  """
  def meta, do: %Terreno{simbolo: "M", nombre: "meta", transitable: true, costo: 1}
end
