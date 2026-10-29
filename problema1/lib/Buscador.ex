defmodule Buscador do
  @moduledoc """
  Encuentra los recorridos válidos entre el inicio y la meta de una cuadrícula.

  La búsqueda usa backtracking, explora vecinos en el orden arriba, derecha,
  abajo e izquierda, y descarta rutas que repiten posiciones o exceden el
  presupuesto de batería.
  """

  @direcciones [
    {-1, 0},
    {0, 1},
    {1, 0},
    {0, -1}
  ]

  @doc """
  Busca todos los recorridos que respetan la transitabilidad y el presupuesto.

  El mapa de entrada debe incluir `:bateria`, `:mapa`, `:inicio` y `:meta`, tal
  como los produce `CargadorDatos.cargar_todo/3`. Devuelve una lista de
  `%Recorrido{}`; si no existe ninguna ruta válida, devuelve `[]`.
  """
  def buscar_todos_los_recorridos(%{
    bateria: presupuesto_bateria,
    mapa: mapa_coordenadas,
    inicio: pos_inicio,
    meta: pos_meta
  }) do
    recorrido_inicial = Recorrido.nuevo([pos_inicio], 0)
    visitados_inicial = MapSet.new([pos_inicio])

    explorar(
      pos_inicio,
      pos_meta,
      mapa_coordenadas,
      presupuesto_bateria,
      recorrido_inicial,
      visitados_inicial
    )
  end

  # ===================================================================
  # Caso Base: Llegada a la Meta 'M'
  # ===================================================================

  defp explorar(pos_meta, pos_meta, _mapa, _bateria, recorrido_actual, _visitados) do
    # Cuando alcanzamos la meta, normalizamos el recorrido (invirtiendo la lista)
    [Recorrido.normalizar_camino(recorrido_actual)]
  end

  # ===================================================================
  # Caso Recursivo: Avance por Vecinos (Backtracking)
  # ===================================================================

  defp explorar(
         pos_actual,
         pos_meta,
         mapa_coordenadas,
         presupuesto_bateria,
         recorrido_actual,
         visitados
       ) do
    # Mantenemos el orden fijo: Arriba, Derecha, Abajo, Izquierda
    evaluar_direcciones(
      @direcciones,
      pos_actual,
      pos_meta,
      mapa_coordenadas,
      presupuesto_bateria,
      recorrido_actual,
      visitados,
      _recorridos_encontrados = []
    )
  end

  defp evaluar_direcciones(
         [{df, dc} | resto_direcciones],
         {fila_actual, col_actual},
         pos_meta,
         mapa,
         bateria,
         recorrido,
         visitados,
         recorridos_acumulados
       ) do
    pos_vecina = {fila_actual + df, col_actual + dc}

    recorridos_desde_vecino =
      if MapSet.member?(visitados, pos_vecina) do
        []
      else
        terreno_vecino = Map.get(mapa, pos_vecina)

        evaluar_paso_terreno(
          pos_vecina,
          terreno_vecino,
          pos_meta,
          mapa,
          bateria,
          recorrido,
          visitados
        )
      end

    # Backtracking: acumulamos las rutas halladas en esta direccion y continuamos con las demas
    evaluar_direcciones(
      resto_direcciones,
      {fila_actual, col_actual},
      pos_meta,
      mapa,
      bateria,
      recorrido,
      visitados,
      recorridos_acumulados ++ recorridos_desde_vecino
    )
  end

  # ===================================================================
  # Evaluacion de Terreno mediante Pattern Matching
  # ===================================================================

  defp evaluar_direcciones(
         [],
         _pos_actual,
         _pos_meta,
         _mapa,
         _bateria,
         _recorrido,
         _visitados,
         recorridos_acumulados
       ),
       do: recorridos_acumulados

  # Pattern Matching 1: Terreno Fuera de Límites (nil) -> Rechazado
  defp evaluar_paso_terreno(
         _pos,
         nil,
         _pos_meta,
         _mapa,
         _bateria,
         _recorrido,
         _visitados
       ),
       do: []

  # Pattern Matching 2: Terreno NO Transitable (%Terreno{transitable: false}) -> Rechazado explícito
  defp evaluar_paso_terreno(
         _pos,
         %Terreno{transitable: false},
         _pos_meta,
         _mapa,
         _bateria,
         _recorrido,
         _visitados
       ),
       do: []

  # Pattern Matching 3: Terreno Transitable (%Terreno{transitable: true, costo: costo}) -> Evalúa B
  defp evaluar_paso_terreno(
         pos_vecina,
         %Terreno{transitable: true, costo: costo_paso},
         pos_meta,
         mapa,
         bateria_maxima,
         recorrido_actual,
         visitados
       ) do
    nueva_energia = recorrido_actual.energia + costo_paso

    if nueva_energia <= bateria_maxima do
      nuevo_recorrido = Recorrido.agregar_paso(recorrido_actual, pos_vecina, costo_paso)
      nuevos_visitados = MapSet.put(visitados, pos_vecina)

      explorar(
        pos_vecina,
        pos_meta,
        mapa,
        bateria_maxima,
        nuevo_recorrido,
        nuevos_visitados
      )
    else
      [] # Rechazado por superar la batería B
    end
  end

end
