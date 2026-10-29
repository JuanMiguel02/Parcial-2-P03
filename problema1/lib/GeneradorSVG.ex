defmodule GeneradorSVG do
  @tamano 40

  # Colores por defecto para cada símbolo
  @colores %{
    "X" => "#2C3E50",
    "S" => "#2ECC71",
    "M" => "#E74C3C",
    "." => "#ECF0F1",
    "L" => "#F39C12",
    "A" => "#3498DB"
  }

  def generar(datos_juego, resultado_analisis, archivo_salida \\ "ruta_optima.svg") do
    %{mapa: mapa} = datos_juego

    # Calculamos dimensiones dinámicas a partir de las claves {fila, col}
    coordenadas = Map.keys(mapa)
    max_f = coordenadas |> Enum.map(&elem(&1, 0)) |> Enum.max()
    max_c = coordenadas |> Enum.map(&elem(&1, 1)) |> Enum.max()

    ancho = max_c * @tamano
    alto = max_f * @tamano

    # Dibujamos las celdas directamente desde el mapa de coordenadas
    celdas =
      Enum.map(mapa, fn {{f, c}, terreno} ->
        dibujar_celda(terreno, c, f)
      end)

    # Dibujamos la capa superior (Ruta o Leyenda)
    capa_ruta = dibujar_capa_ruta(resultado_analisis, ancho, alto)

    svg = """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{ancho}" height="#{alto}" viewBox="0 0 #{ancho} #{alto}">
      <style>
        .texto-celda { font-family: sans-serif; font-size: 14px; font-weight: bold; text-anchor: middle; dominant-baseline: central; fill: #111; }
        .linea-ruta { stroke: #8E44AD; stroke-width: 5; stroke-linecap: round; stroke-linejoin: round; fill: none; opacity: 0.85; }
        .leyenda { font-family: sans-serif; font-size: 26px; font-weight: bold; fill: #C0392B; text-anchor: middle; dominant-baseline: central; }
      </style>
      <rect width="100%" height="100%" fill="white"/>
      #{Enum.join(celdas, "\n")}
      #{capa_ruta}
    </svg>
    """

    File.write!(archivo_salida, svg)
  end

  defp dibujar_celda(%Terreno{simbolo: simbolo, nombre: nombre}, col, fila) do
    # Conversión a coordenadas base 0 para el lienzo SVG
    px = (col - 1) * @tamano
    py = (fila - 1) * @tamano
    cx = px + div(@tamano, 2)
    cy = py + div(@tamano, 2)

    color = Map.get(@colores, simbolo, "#BDC3C7")
    simbolo_esc = escapar_xml(simbolo)
    nombre_esc = escapar_xml(nombre)

    """
    <rect x="#{px}" y="#{py}" width="#{@tamano}" height="#{@tamano}" fill="#{color}" stroke="#dddddd" stroke-width="0.5">
      <title>#{nombre_esc} (#{fila}, #{col})</title>
    </rect>
    <text x="#{cx}" y="#{cy}" class="texto-celda">#{simbolo_esc}</text>
    """
  end

  defp dibujar_capa_ruta({:ok, %{ruta_optima_svg: %Recorrido{posiciones: pos}}}, _ancho, _alto) do
    puntos =
      pos
      |> Enum.map(fn {f, c} ->
        cx = (c - 1) * @tamano + div(@tamano, 2)
        cy = (f - 1) * @tamano + div(@tamano, 2)
        "#{cx},#{cy}"
      end)
      |> Enum.join(" ")

    """
    <polyline points="#{puntos}" class="linea-ruta" />
    """
  end

  defp dibujar_capa_ruta({:error, :sin_recorridos}, ancho, alto) do
    cx = div(ancho, 2)
    cy = div(alto, 2)

    """
    <rect x="0" y="0" width="#{ancho}" height="#{alto}" fill="black" fill-opacity="0.3"/>
    <rect x="#{cx - 110}" y="#{cy - 25}" width="220" height="50" fill="white" rx="5" stroke="#C0392B" stroke-width="2"/>
    <text x="#{cx}" y="#{cy}" class="leyenda">sin recorrido</text>
    """
  end

  defp escapar_xml(str) do
    str
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
