defmodule Analizador do
  @moduledoc """
  Procesa la lista de %Recorrido{} generada por el Buscador para calcular
  las metricas requeridas: totales, mínimos de movimientos, mínimos de energía
  y selección de la ruta óptima para el SVG.
  """

  @doc """
  Analiza la lista de recorridos y retorna un mapa estructurado con las métricas.

  Si la lista está vacía, retorna `{:error, :sin_recorridos}`.
  Si existen rutas válidas, retorna `{:ok, %{total: int, menos_movimientos: list, menor_energia: list, ruta_optima_svg: struct}}`.
  """
  def analizar([]) do
    {:error, :sin_recorridos}
  end

  def analizar(recorridos) when is_list(recorridos) do
    total_recorridos = length(recorridos)

    min_movimientos_valor =
      recorridos
      |> Enum.map(&calcular_movimientos/1)
      |> Enum.min()

    menos_movimientos = Enum.filter(recorridos, fn recorrido -> calcular_movimientos(recorrido) == min_movimientos_valor end)

    min_energia_valor =
      recorridos
      |> Enum.map(& &1.energia)
      |> Enum.min()

    menor_energia = Enum.filter(recorridos, fn recorrido -> recorrido.energia == min_energia_valor end)

    ruta_optima_svg = List.first(menor_energia)

    {:ok,
     %{
       total: total_recorridos,
       menos_movimientos: menos_movimientos,
       movimientos_minimos: min_movimientos_valor,
       menor_energia: menor_energia,
       energia_minima: min_energia_valor,
       ruta_optima_svg: ruta_optima_svg
     }}
  end

  @doc """
  Calcula la cantidad de movimientos realizados en un recorrido.
  Dado que 'posiciones' incluye la celda inicial 'S', los movimientos equivalen a posiciones - 1.
  """
  def calcular_movimientos(%Recorrido{posiciones: posiciones}) do
    max(0, length(posiciones) - 1)
  end
end
