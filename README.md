# Registro de Calabazas · The Halfling's Finds

Sistema de control de inventario para calabazas tejidas a mano. Captura desde el celular, sincroniza entre dispositivos y exporta a Excel para análisis.

Funciona sin internet y sube los cambios solo cuando vuelve la señal.

---

## Qué resuelve

Un inventario de piezas artesanales tiene un problema que un inventario normal no tiene: **no hay dos iguales**. Dos calabazas de la misma talla pueden ser productos comercialmente distintos según su color, su textura y sus adornos.

Este sistema registra cada pieza como un individuo, con su código propio, y guarda los atributos que después explican por qué unas se venden y otras no.

**Lo que responde:**

- Qué talla y qué familia de color rotan más rápido
- Cuántos días tarda en venderse cada tipo de pieza en cada punto de venta
- Si los madroños, la rafia y las hojas de plástico se pagan solos
- Cuánto dinero hay parado en inventario, a costo y a precio de venta
- Qué piezas quedaron rezagadas de temporadas anteriores

---

## Cómo funciona

**Una fila = una calabaza física.** Cada pieza nace con una etiqueta que la acompaña hasta que se vende. El código nunca se reutiliza.

### El código

```
26-A001
│  │ └── consecutivo dentro de esa talla
│  └──── letra de la talla (A = tipo 0, B = tipo 1 … H = tipo 8, I = juego de 3)
└─────── temporada
```

La app calcula el consecutivo sola, contando lo que ya existe en la nube. Si ya hay una B011, la siguiente talla 1 sale como B012 — aunque la hayas capturado en otro dispositivo.

El año permite distinguir de un vistazo el inventario rezagado del nuevo. Para dar de alta piezas de la temporada pasada se cambia la temporada a `25` en Ajustes de captura.

### Las tallas

| Letra | Tipo | Base (cm) | Altura (cm) | Contorno (cm) | Puntos |
|---|---|---|---|---|---|
| A | 0 | 5 – 6.5 | 3 – 4 | 13 – 15 | 24 |
| B | 1 | 6 – 8 | 4 – 5 | 19 – 21 | 40 |
| C | 2 | 9 – 11.5 | 5 – 7 | 25 – 33 | 56 |
| D | 3 | 12 – 15 | 7 – 9 | 37 – 43 | 72 |
| E | 5 | 16 – 22 | 9 – 11 | 48 – 55 | 120 |
| F | 6 | 23 – 25 | 11 – 14 | 58 – 65 | 140 |
| G | 7 | 26 – 34 | 14 – 22 | 71 – 91 | 160 |
| H | 8 | 35 – 42 | 22 – 31 | 100 – 116 | 184 |
| I | Juego de 3 | 16 – 25 | 20 – 30 | 44 – 72 | variado |

El **tipo 4 fue retirado**: ya no se teje. El juego de 3 se compone de las tallas 7, 6 y 5.

Al capturar, si una medida real cae fuera del rango de la talla elegida, la app lo avisa sin impedir el guardado — sirve para detectar errores de clasificación, no para bloquear.

### El ciclo de una pieza

| Momento | Qué se hace |
|---|---|
| Nace | Se da de alta con sus características. Estado: `EN ALMACÉN` |
| Sale a un punto de venta | Estado `ASIGNADA` + canal + fecha de asignación |
| Se vende | Estado `VENDIDA` + fecha de venta + precio real |
| Regresa o se daña | Estado `DEVUELTA` o `DAÑADA` |

Para registrar una venta no se captura de nuevo: se busca el código en la pestaña Inventario, se presiona **Editar** y se cambia el estado.

### Campos obligatorios y opcionales

Lo mínimo para guardar una pieza es **la talla**. Todo lo demás puede quedar vacío.

Los bloques de **Producción y costo** y **Medidas reales** vienen plegados y marcados como opcionales, porque no siempre se tienen a la mano — sobre todo cuando captura alguien más. La etiqueta del bloque cambia a *Con datos* cuando se llenó algo.

Consecuencia a tener presente: las piezas sin costo no aparecen en el análisis de margen, pero sí en todo el análisis de mercado (talla, color, textura, días en piso).

---

## Instalación

Se necesitan dos servicios, ambos en plan gratuito.

### 1. Base de datos — Supabase

1. Crear proyecto nuevo en [supabase.com](https://supabase.com).
2. Ir a **SQL Editor** → *New query*, pegar el contenido de [`supabase-setup.sql`](supabase-setup.sql) y presionar **RUN**. El script es idempotente: se puede correr más de una vez sin romper nada.
3. Ir a **Authentication → Users → Add user** y crear el usuario. **Marcar la casilla de auto-confirmar el correo**, o no será posible iniciar sesión.
4. Copiar de **Project Settings → API** los dos datos de conexión: *Project URL* y *anon public key*.

### 2. Publicación — Netlify

Conectar este repositorio en [Netlify](https://app.netlify.com) mediante *Add new site → Import an existing project → GitHub*.

Dejar **vacíos** los campos de *Build command* y *Publish directory*: el proyecto es un archivo estático y no necesita compilarse.

### 3. Conexión

Abrir la dirección publicada, ir a la pestaña **Inventario** → *Conexión con la nube*, pegar la URL y la llave, escribir correo y contraseña y presionar **Conectar**.

Se hace una sola vez por dispositivo. Las credenciales quedan guardadas únicamente en ese dispositivo.

Para que se comporte como aplicación:
- **iPhone**: Safari → compartir → *Añadir a pantalla de inicio*
- **Android**: Chrome → menú → *Añadir a pantalla principal*

---

## Sincronización

| Situación | Comportamiento |
|---|---|
| Se guarda una pieza con internet | Se sube de inmediato |
| Se guarda sin internet | Queda marcada *por subir* y se manda sola al reconectar |
| App abierta al frente | Revisa cambios cada minuto |
| Dos dispositivos editan la misma pieza | Gana el cambio más reciente |
| Se borra una pieza | Se elimina también en los demás dispositivos |

El indicador de la parte superior muestra el estado: verde sincronizado, amarillo con pendientes, gris sin conectar.

---

## Exportar al Excel de análisis

El botón **Descargar Excel** genera un archivo con las 38 columnas del *Maestro de Piezas* en el mismo orden. Se copia el bloque de filas y se pega en el libro de análisis a partir de la fila 5.

Las columnas calculadas (familia de color, puntos, costos derivados, precio sugerido, días en piso, márgenes) salen vacías a propósito: las fórmulas del libro las llenan al pegar.

También se pueden descargar todas las fotos en un zip, cada una nombrada con su código.

---

## Impresión de etiquetas

`etiquetas.html` genera los colgantes numerados **antes** de capturar, para poder etiquetar las piezas físicamente y llenar los datos después.

Se elige temporada, talla y rango (por ejemplo `26-B001` a `26-B025`) y se imprime en tamaño carta: 16 etiquetas por hoja. Se pueden acumular varias tallas en una misma impresión con *Agregar otra talla*.

Cada etiqueta trae el cuerpo con el código y la talla, y el talón desprendible con la sigla, el identificador y el precio. La línea punteada del centro es por donde se arranca el talón al vender la pieza.

Al imprimir hay que activar **Gráficos de fondo** para que salga el color, y usar cartulina de 180–200 g.

---

## Respaldos

El botón **Crear respaldo** descarga un `.json` con todo el inventario. Conviene hacerlo al terminar cada sesión fuerte de captura y guardarlo fuera del dispositivo.

**Cargar respaldo** lo restaura sin duplicar: las piezas cuyo código ya existe se ignoran.

---

## Requisitos y límites

- Navegador moderno. La cámara requiere que el sitio corra en **https**; abriendo el archivo local no funciona.
- Las fotos se reducen a 900 px y se comprimen antes de guardarse (~80 KB cada una).
- El plan gratuito de Supabase da 500 MB de base y 1 GB de almacenamiento, suficiente para unas 3,000 piezas con foto.
- Supabase **pausa los proyectos gratuitos tras 7 días sin actividad**. Se reactivan desde el panel con *Restore*, sin pérdida de datos.

---

## Seguridad

Sin sesión iniciada no se ve nada, aunque se tenga el enlace: las políticas de acceso de la base exigen usuario autenticado para leer, crear, editar o borrar.

**Las credenciales no viven en el código.** La URL del proyecto, la llave pública, el correo y la contraseña se escriben en la app y se guardan solo en el dispositivo. Por eso este repositorio puede ser público sin exponer nada.

Si en algún momento se agregan credenciales dentro del archivo, el repositorio debe volverse privado.

---

## Estructura

```
index.html            La aplicación completa, en un solo archivo
etiquetas.html        Generador de colgantes numerados para imprimir
supabase-setup.sql    Script de instalación de la base de datos
README.md             Este documento
LICENSE               Términos de uso
```

No hay dependencias que instalar. Las únicas librerías externas (SheetJS y JSZip) se cargan bajo demanda al exportar, y solo en ese momento hace falta internet.

---

## Autoría

Desarrollado para **The Halfling's Finds**. Ver [LICENSE](LICENSE) para los términos de uso.
