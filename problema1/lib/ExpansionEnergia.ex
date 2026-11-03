defmodule ExpansionEnergia do
  @moduledoc """
  Calcula progresivamente el costo mínimo para alcanzar las casillas transitables
  de un mapa, respetando un límite de batería.

  Los estados se representan como mapas `%{{fila, columna} => costo}`. La
  expansión considera movimientos ortogonales y el costo del terreno al entrar
  en cada casilla.
  """

  @doc """
  Genera un stream de estados sucesivos de la expansión de energía.

  El primer estado contiene únicamente la posición inicial con costo `0`. Cada
  estado posterior agrega las casillas alcanzables con el menor costo conocido
  hasta ese paso. El stream es infinito; quien lo consuma debe detenerse cuando
  los estados consecutivos sean iguales o al alcanzar otro límite.

  ## Parámetros

    * `mapa` - mapa que asocia coordenadas `{fila, columna}` con terrenos que
      incluyen `:transitable` y `:costo`.
    * `pos_inicio` - coordenada desde la que comienza la expansión.
    * `bateria` - costo máximo permitido para incluir una casilla.

  Cada elemento emitido es un mapa de coordenadas alcanzadas a sus costos
  mínimos conocidos.
  """
  def generar_stream(mapa, pos_inicio, bateria) do
    estado_inicial = %{pos_inicio => 0}

    Stream.unfold(estado_inicial, fn estado_actual ->
      siguiente_estado = relajar_paso(estado_actual, mapa, bateria)
      {estado_actual, siguiente_estado}
    end)
  end

  defp relajar_paso(costos_actuales, mapa, bateria) do
    # Conservamos los costos que ya habíamos encontrado en pasos anteriores
    Enum.reduce(mapa, costos_actuales, fn {coord, terreno}, acc_costos ->
      # Solo procesamos casillas transitables
      if terreno.transitable do
        case calcular_menor_costo_desde_vecinos(coord, terreno.costo, costos_actuales, mapa) do
          nil ->
            # Ningún vecino alcanzado todavía, no se puede calcular costo
            acc_costos

          nuevo_costo ->
            if nuevo_costo <= bateria do
              costo_previo = Map.get(acc_costos, coord)

              # Solo reemplazamos el costo si esta iteración encontró uno menor.
              menor =
                if is_nil(costo_previo) do
                  nuevo_costo
                else
                  min(costo_previo, nuevo_costo)
                end

              Map.put(acc_costos, coord, menor)
            else
              # Si supera la batería B, no se incluye
              acc_costos
            end
        end
      else
        acc_costos
      end
    end)
  end

  defp calcular_menor_costo_desde_vecinos({fila, col}, costo_entrada, costos_actuales, _mapa) do
    vecinos = [
      {fila - 1, col},
      {fila, col + 1},
      {fila + 1, col},
      {fila, col - 1}
    ]

    # Se usa el estado anterior completo: así cada paso propaga el alcance una casilla más.
    costos_posibles =
      for v <- vecinos,
          costo_v = Map.get(costos_actuales, v),
          not is_nil(costo_v) do
        costo_v + costo_entrada
      end

    case costos_posibles do
      [] -> nil
      lista -> Enum.min(lista)
    end
  end
end
