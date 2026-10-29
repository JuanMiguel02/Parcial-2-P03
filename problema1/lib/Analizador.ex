defmodule Analizador do
  @moduledoc """
  Calcula métricas de los recorridos encontrados por `Buscador`.

  Para una lista no vacía, `analizar/1` devuelve el total de recorridos, los
  recorridos con menos movimientos y los de menor energía. También selecciona
  el primer recorrido de menor energía para usarlo como ruta del SVG.
  """

  @doc """
  Analiza recorridos y devuelve sus métricas agrupadas en un mapa.

  Devuelve `{:error, :sin_recorridos}` para una lista vacía. Para una lista no
  vacía, devuelve `{:ok, metricas}`, donde `metricas` incluye `:total`,
  `:menos_movimientos`, `:movimientos_minimos`, `:menor_energia`,
  `:energia_minima` y `:ruta_optima_svg`.

  ## Parámetros

    * `recorridos` - lista de estructuras `%Recorrido{}`.
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
  Calcula la cantidad de movimientos de un `%Recorrido{}`.

  Como `posiciones` incluye la celda inicial, el número de movimientos es la
  cantidad de posiciones menos uno. El resultado nunca es negativo.
  """
  def calcular_movimientos(%Recorrido{posiciones: posiciones}) do
    max(0, length(posiciones) - 1)
  end
end
