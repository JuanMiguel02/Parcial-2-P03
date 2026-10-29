defmodule Recorrido do
  @moduledoc """
  Estructura que representa un camino de celdas y su consumo de energía.

  Las posiciones se almacenan como coordenadas `{fila, columna}`. Durante la
  búsqueda pueden estar en orden inverso; `normalizar_camino/1` las ordena desde
  el inicio hasta la meta.
  """

  @enforce_keys [:posiciones, :energia]
  defstruct [posiciones: [], energia: 0]

  @typedoc """
  Recorrido por la cuadrícula y energía total consumida.
  """
  @type t :: %__MODULE__{
          posiciones: [{pos_integer(), pos_integer()}],
          energia: integer()
        }

  @doc """
  Crea un recorrido con las posiciones y la energía indicadas.

  Por defecto, crea un recorrido vacío con energía cero.
  """
  def nuevo(posiciones \\ [], energia \\ 0) do
    %Recorrido{posiciones: posiciones, energia: energia}
  end

  @doc """
  Añade una posición al recorrido e incrementa la energía consumida.

  La nueva posición se agrega al principio de la lista; usa
  `normalizar_camino/1` para obtener el orden desde el inicio hasta la meta.
  """
  def agregar_paso(%Recorrido{posiciones: pos, energia: e_actual}, nueva_pos, costo_paso) do
    %Recorrido{
      posiciones: [nueva_pos | pos],
      energia: e_actual + costo_paso
    }
  end

  @doc """
  Devuelve el recorrido con las posiciones en orden desde el inicio hasta la meta.

  La energía total no se modifica.
  """
  def normalizar_camino(%Recorrido{posiciones: pos} = recorrido) do
    %{recorrido | posiciones: Enum.reverse(pos)}
  end
end
