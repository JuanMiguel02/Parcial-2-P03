# Parcial 2 - Programación III - G2D

Este repositorio contiene la solución a dos de los problemas propuestos en el segundo parcial de Programación III. Los ejercicios abordan conceptos de programación funcional en **Elixir**, haciendo énfasis en el uso de recursividad pura, estructuras (`structs`), evaluación perezosa y manejo de flujos de datos (`Streams`).

## Descripción de los problemas resueltos

### Problema 1: Robot de rescate con energía limitada y mapa SVG
Este problema consiste en encontrar recursivamente todos los recorridos simples que un robot puede hacer desde un punto de inicio (**S**) hasta una meta (**M**) dentro de una cuadrícula que representa un edificio. El robot cuenta con un presupuesto de energía (**B**) que se va consumiendo según el tipo de terreno que pise. 
El algoritmo determina el número total de caminos válidos, destaca los más cortos y los de menor consumo, y finalmente dibuja la ruta óptima mediante la generación de un archivo de imagen vectorial (SVG).

### Problema 3: Búsqueda de motivos de ADN con hasta un error
Este ejercicio se enfoca en la bioinformática. El objetivo es procesar secuencias genéticas (muestras) y buscar coincidencias con un conjunto de motivos cortos de ADN. La búsqueda se realiza tanto en la hebra directa como en la reversa complementaria, permitiendo una tolerancia máxima de un error por sustitución de nucleótidos. 
El programa contabiliza las frecuencias, detecta qué motivos no aparecieron y genera un reporte detallado en formato CSV de todas las ventanas encontradas.

---

## Organización de carpetas

El proyecto está diseñado bajo una arquitectura modular para separar los datos, la lógica del negocio y los reportes generados. Cada problema tiene su propio directorio independiente con la siguiente estructura base:

```text
/Parcial-2-P03
│
├── /problema1                    # Solución al Robot de Rescate
│   ├── /data                     # Archivos de entrada (bateria.txt, edificio.txt, terrenos.csv)
│   ├── /lib                      # Módulos de Elixir (.ex)
│   │   ├── /structs              # Definición de estructuras (Recorrido.ex, Terreno.ex)
│   │   └── (Módulos de validación, búsqueda, carga y SVG)
│   ├── /salidas                  # Carpeta con los reportes (.csv, .txt, .svg)
│   └── main.exs                  # Script ejecutable principal del problema 1
│
└── /problema3                    # Solución a la Búsqueda de ADN
    ├── /data                     # Archivos de entrada (motivos.txt, muestras)
    ├── /lib                      # Módulos de Elixir (.ex)
    │   ├── /structs              # Definición de estructuras (Coincidencia.ex)
    │   └── (Módulos de validación, búsqueda, carga y reporte)
    ├── /salidas                  # Carpeta con los reportes (.csv, .txt)
    └── main.exs                  # Script ejecutable principal del problema 3
```

## Requisitos Previos

Para clonar y ejecutar este proyecto en tu máquina local, asegúrese de contar con:

* **Elixir** (versión `1.14` o superior recomendada).
* **Erlang/OTP** (incluido automáticamente al instalar Elixir).
* **Git** (para clonar y administrar el repositorio).
* *(Opcional)* **Python 3** (si deseas utilizar un script ejecutable auxiliar).

---

## Guía Paso a Paso: Clonar y Ejecutar

### Paso 1: Clonar el Repositorio de GitHub

Abre la terminal de tu sistema operativo (*PowerShell, Command Prompt, Terminal de macOS/Linux o Git Bash*) o la terminal integrada de Visual Studio Code y ejecuta:

```bash
git clone https://github.com/JuanMiguel02/Parcial-2-P03.git
cd Parcial-2-P03
```

### Paso 2: Ejecución de los Programas

Puedes ejecutar las soluciones de dos formas diferentes: mediante los scripts ejecutables de Python o de forma manual directamente con Elixir.

#### Opción A: Ejecución mediante Scripts de Python (Recomendado desde la raíz)

El repositorio incluye dos scripts en Python en la carpeta raíz (`ejecutar1.py` y `ejecutar3.py`). Estos scripts verifican automáticamente la existencia del intérprete de Elixir en el sistema, validan la presencia de los archivos `main.exs` y ajustan el directorio de trabajo antes de iniciar el proceso.

- **Para ejecutar el Problema 1 (Robot de Rescate):**
```bash
python ejecutar1.py
```

- **Para ejecutar el Problema 3 (Búsqueda de ADN):**
```bash
python ejecutar3.py
```

> **Nota:** En algunos sistemas (como Linux o macOS), el comando de Python puede ser `python3`:
> ```bash
> python3 ejecutar1.py
> python3 ejecutar3.py
> ```

#### Opción B: Ejecución Manual con Elixir

Si prefieres invocar directamente el intérprete de Elixir sin pasar por Python, puedes desplazarte a la carpeta correspondiente a cada ejercicio y lanzar el punto de entrada `main.exs`:

- **Ejecución del Problema 1:**
```bash
cd problema1
elixir main.exs
```
*(Para regresar a la raíz al finalizar: `cd ..`)*

- **Ejecución del Problema 3:**
```bash
cd problema3
elixir main.exs
```
*(Para regresar a la raíz al finalizar: `cd ..`)*

## Auditoría y Casos de Prueba (Válidos, Inválidos y Límite)

El proyecto incluye evaluaciones para auditar la solidez y el comportamiento de ambos programas (Problema 1 y Problema 3) ante tres escenarios de prueba fundamentales:

### 1. Caso Válido
* **Descripción:** Archivos de entrada bien estructurados en la carpeta `data/` que cumplen con toda la sintaxis y reglas del problema.
* **Comportamiento:** La validación previa recursiva aprueba los archivos, se ejecuta el núcleo algorítmico y se generan de forma exitosa los reportes correspondientes en la carpeta `salidas/` (`.csv`, `.txt` y gráficos `.svg`).

### 2. Caso Inválido
* **Descripción:** Archivos con fallas sintácticas o estructurales (p. ej., caracteres ajenos a **A, C, G, T** en ADN, identificadores vacíos, bordes del mapa que no son **X**, baterías negativas **B < 0** o ausencia de punto de inicio **S** / meta **M**).
* **Comportamiento:** El módulo de validación previa recursiva interrumpe inmediatamente la ejecución antes de iniciar la búsqueda y escribe un informe detallado con la línea física o coordenada del error en `salidas/validacion_edificio.txt` o `salidas/validacion_adn.txt`.

### 3. Caso Límite
* **Descripción:** Datos formalmente válidos que operan en las fronteras extremas de la lógica del sistema:
  * **Problema 1:** Presupuesto de batería **B** exactamente justo para completar el recorrido mínimo, o un edificio con la meta **M** acorralada donde existen $0$ rutas transitables.
  * **Problema 3:** Motivos con longitud idéntica o superior a la secuencia de la muestra, o coincidencias en los extremos exactos (índice 0 o final de cadena) con el máximo error permitido (1 sustitución).
* **Comportamiento:** El programa procesa la información de forma segura sin lanzar excepciones no controladas ni desbordar la memoria, gestionando perezosamente los descartes y reportando los resultados finales exactos.
