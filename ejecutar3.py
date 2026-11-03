"""Ejecuta el punto de entrada Elixir ubicado en ``problema3/main.exs``.

Requiere que Elixir esté instalado y que el comando ``elixir`` esté disponible
en el ``PATH`` del sistema.
"""

# Permite iniciar un proceso externo, en este caso el intérprete de Elixir.
import subprocess
# Da acceso al sistema operativo, incluyendo la plataforma y la salida de error.
import sys
# Permite construir y comprobar rutas de archivos de forma portable.
from pathlib import Path
# Busca el ejecutable de Elixir en las carpetas configuradas en PATH.
from shutil import which


def ejecutar_main():
    """Ejecuta ``main.exs`` y devuelve el código de salida del proceso.

    Devuelve ``1`` si falta la carpeta del programa, el archivo de entrada o
    el ejecutable de Elixir, o si no se puede iniciar el proceso. Los errores
    propios de la ejecución se representan mediante el código de salida de
    Elixir.
    """
    # Obtiene la carpeta donde está este script y añade la carpeta del programa.
    carpeta_programa = Path(__file__).resolve().parent / "problema3"
    # Construye la ruta al archivo Elixir que se va a ejecutar.
    archivo_main = carpeta_programa / "main.exs"

    # Comprueba que exista la carpeta del programa antes de continuar.
    if not carpeta_programa.is_dir():
        # Informa del error en stderr, reservado para mensajes de error.
        print(f"Error: No se encontró la carpeta '{carpeta_programa}'.", file=sys.stderr)
        # Termina la función con código 1 para indicar que no pudo ejecutarse.
        return 1

    # Comprueba que el archivo de entrada exista dentro de la carpeta esperada.
    if not archivo_main.is_file():
        # Muestra la ruta del archivo que no se encontró.
        print(f"Error: No se encontró el archivo '{archivo_main}'.", file=sys.stderr)
        # Informa al sistema que ocurrió un error.
        return 1

    # Busca el comando ejecutable de Elixir en el PATH del sistema.
    ejecutable_elixir = which("elixir")
    # Si no se encuentra, no es posible iniciar el programa Elixir.
    if ejecutable_elixir is None:
        # Indica cómo resolver el problema y envía el mensaje a stderr.
        print(
            "Error: no se encontró Elixir. Instálalo y agrega su carpeta bin "
            "al PATH, luego vuelve a abrir la terminal.",
            file=sys.stderr,
        )
        # Devuelve un código distinto de cero para señalar el fallo.
        return 1

    # Informa de la plataforma y del directorio desde donde se ejecutará Elixir.
    print(f"Ejecutando en {sys.platform} dentro de: {carpeta_programa}\n{'-' * 50}")

    # Captura errores del sistema que puedan impedir iniciar el proceso externo.
    try:
        # Ejecuta Elixir con main.exs como argumento, dentro de problema3.
        resultado = subprocess.run(
            # Usa la ruta encontrada por which y evita depender del shell.
            [ejecutable_elixir, "main.exs"],
            # Establece el directorio de trabajo para que main.exs encuentre sus recursos.
            cwd=carpeta_programa,
            # Permite inspeccionar el código de salida sin lanzar excepción por fallos.
            check=False,
        )
    # OSError cubre errores del sistema al iniciar el ejecutable.
    except OSError as error:
        # Informa del motivo concreto por el que no se pudo iniciar Elixir.
        print(f"Error al iniciar Elixir: {error}", file=sys.stderr)
        # Devuelve código de error al proceso que lanzó este script.
        return 1

    # Un código distinto de cero indica que main.exs terminó con error.
    if resultado.returncode != 0:
        # Muestra el código de salida que devolvió el proceso de Elixir.
        print(
            f"El programa finalizó con errores (código {resultado.returncode}).",
            file=sys.stderr,
        )

    # Propaga el código de salida de Elixir para reflejar el resultado real.
    return resultado.returncode


# Solo ejecuta el programa cuando este archivo se inicia directamente,
# no cuando se importa desde otro módulo de Python.
if __name__ == "__main__":
    # Termina Python usando el código devuelto por ejecutar_main().
    sys.exit(ejecutar_main())