defmodule Recorrido do
  @enforce_keys [:posiciones, :energia]
  defstruct [posiciones: [], energia: 0]

  @doc """
  Crea una nueva instancia de %Recorrido{}.
  """
  def nuevo(posiciones \\ [], energia \\ 0) do
    %Recorrido{posiciones: posiciones, energia: energia}
  end

  @doc """
  Añade una posición al recorrido actual e incrementa el consumo de energía.
  """
  def agregar_paso(%Recorrido{posiciones: pos, energia: e_actual}, nueva_pos, costo_paso) do
    %Recorrido{
      posiciones: [nueva_pos | pos],
      energia: e_actual + costo_paso
    }
  end

  @doc """
  Devuelve el recorrido con el orden de posiciones invertido (de Inicio a Meta).
  """
  def normalizar_camino(%Recorrido{posiciones: pos} = recorrido) do
    %{recorrido | posiciones: Enum.reverse(pos)}
  end

end
