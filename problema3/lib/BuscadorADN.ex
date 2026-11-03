defmodule BuscadorADN do
  @moduledoc """
  Módulo que realiza la búsqueda de motivos de ADN con hasta un error
  en hebra directa y reversa complementaria.
  """

  @doc """
  Busca todas las coincidencias válidas en las muestras y las ordena según los criterios.
  """
  def buscar_coincidencias({muestras, motivos}) do
    for {muestra_id, secuencia} <- muestras,
        motivo <- motivos,
        {orientacion, sec_trabajo} <- [{"+", secuencia}, {"-", reversa_complementaria(secuencia)}],
        coincidencia <- buscar_en_secuencia(sec_trabajo, motivo, orientacion, muestra_id) do
      coincidencia
    end
    |> Enum.sort_by(fn c ->
      {c.muestra, c.motivo, c.inicio, if(c.orientacion == "+", do: 0, else: 1)}
    end)
  end

  @doc """
  Devuelve el nucleótido complementario para una base dada.
  """
  def complemento(?A), do: ?T
  def complemento(?T), do: ?A
  def complemento(?C), do: ?G
  def complemento(?G), do: ?C
  def complemento(c), do: c

  @doc """
  Construye de forma recursiva la reversa complementaria de una cadena.
  """
  def reversa_complementaria(cadena) do
    cadena
    |> String.to_charlist()
    |> rc_rec([])
    |> List.to_string()
  end

  defp rc_rec([], acc), do: acc
  defp rc_rec([h | t], acc), do: rc_rec(t, [complemento(h) | acc])

  defp contar_diferencias(vent, mot) do
    contar_dif_rec(String.to_charlist(vent), String.to_charlist(mot), 0)
  end

  defp contar_dif_rec([], [], acc), do: acc
  defp contar_dif_rec([vh | vt], [mh | mt], acc) do
    nuevo_acc = if vh != mh, do: acc + 1, else: acc
    if nuevo_acc > 1, do: 2, else: contar_dif_rec(vt, mt, nuevo_acc)
  end

  defp buscar_en_secuencia(secuencia, motivo, orientacion, muestra_id) do
    l_sec = String.length(secuencia)
    l_mot = String.length(motivo)

    if l_mot > l_sec do
      []
    else
      buscar_ventanas(secuencia, motivo, orientacion, muestra_id, 0, l_sec, l_mot, [])
    end
  end

  defp buscar_ventanas(_sec, _mot, _ori, _m, idx, l_sec, l_mot, acc) when idx + l_mot > l_sec do
    Enum.reverse(acc)
  end
  defp buscar_ventanas(sec, mot, orientacion, muestra, idx, l_sec, l_mot, acc) do
    ventana = String.slice(sec, idx, l_mot)
    dif = contar_diferencias(ventana, mot)

    nuevo_acc = if dif <= 1 do
      [
        %Coincidencia{
          muestra: muestra,
          motivo: mot,
          orientacion: orientacion,
          inicio: idx,
          fin: idx + l_mot - 1,
          diferencias: dif
        }
        | acc
      ]
    else
      acc
    end

    buscar_ventanas(sec, mot, orientacion, muestra, idx + 1, l_sec, l_mot, nuevo_acc)
  end
end
