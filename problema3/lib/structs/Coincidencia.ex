defmodule Coincidencia do
  @moduledoc """
  Define la estructura de datos para almacenar la información de una coincidencia
  de motivo de ADN encontrada en las secuencias de muestra.
  """
  defstruct [:muestra, :motivo, :orientacion, :inicio, :fin, :diferencias]

end
