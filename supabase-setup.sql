-- =====================================================================
--  RINCÓN DELIZZÉ · Inventario de calabazas
--  Script de instalación para Supabase
--  Pégalo completo en el SQL Editor de Supabase y presiona RUN.
--  Es seguro correrlo más de una vez.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. La tabla de piezas
--    Una fila = una calabaza física. La etiqueta es la llave: no puede
--    haber dos calabazas con el mismo código.
-- ---------------------------------------------------------------------
create table if not exists public.piezas (
  etiqueta          text primary key,
  temporada         smallint,
  tipo              text,
  color             text,
  familia           text,
  textura           text,
  madronos          text,
  gajos             numeric,
  rabo              text,
  hojas             text,
  rafia             text,
  flores            text,
  diam              numeric,
  alt               numeric,
  circ              numeric,
  tejedora          text,
  fecha_produccion  date,
  marca_hilo        text,
  color_hilo        text,
  madejas           numeric,
  costo_madeja      numeric,
  costo_relleno     numeric,
  costo_adornos     numeric,
  estado            text,
  canal             text,
  fecha_asignacion  date,
  fecha_venta       date,
  precio_venta      numeric,
  notas             text,
  foto_url          text,
  creada_en         timestamptz default now(),
  actualizada_en    timestamptz default now()
);

-- Índices que hacen rápidas las consultas del tablero
create index if not exists piezas_estado_idx    on public.piezas (estado);
create index if not exists piezas_canal_idx     on public.piezas (canal);
create index if not exists piezas_temporada_idx on public.piezas (temporada);

-- ---------------------------------------------------------------------
-- 2. Marca de tiempo automática
--    Cada vez que se modifica una fila se actualiza sola. Esto es lo que
--    permite que el celular y la computadora sepan cuál versión es la
--    más nueva cuando las dos tocaron la misma pieza.
-- ---------------------------------------------------------------------
create or replace function public.marcar_actualizacion()
returns trigger
language plpgsql
as $$
begin
  new.actualizada_en = now();
  return new;
end;
$$;

drop trigger if exists piezas_actualizada on public.piezas;
create trigger piezas_actualizada
  before update on public.piezas
  for each row execute function public.marcar_actualizacion();

-- ---------------------------------------------------------------------
-- 3. Seguridad
--    Solo alguien que inició sesión con correo y contraseña puede ver o
--    tocar el inventario. Sin sesión no se ve nada, aunque tenga el link.
-- ---------------------------------------------------------------------
alter table public.piezas enable row level security;

drop policy if exists "leer piezas"      on public.piezas;
drop policy if exists "crear piezas"     on public.piezas;
drop policy if exists "editar piezas"    on public.piezas;
drop policy if exists "borrar piezas"    on public.piezas;

create policy "leer piezas"   on public.piezas for select to authenticated using (true);
create policy "crear piezas"  on public.piezas for insert to authenticated with check (true);
create policy "editar piezas" on public.piezas for update to authenticated using (true) with check (true);
create policy "borrar piezas" on public.piezas for delete to authenticated using (true);

-- ---------------------------------------------------------------------
-- 4. El almacén de fotos
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('calabazas', 'calabazas', true)
on conflict (id) do nothing;

drop policy if exists "ver fotos"      on storage.objects;
drop policy if exists "subir fotos"    on storage.objects;
drop policy if exists "cambiar fotos"  on storage.objects;
drop policy if exists "borrar fotos"   on storage.objects;

create policy "ver fotos"     on storage.objects for select using (bucket_id = 'calabazas');
create policy "subir fotos"   on storage.objects for insert to authenticated with check (bucket_id = 'calabazas');
create policy "cambiar fotos" on storage.objects for update to authenticated using (bucket_id = 'calabazas');
create policy "borrar fotos"  on storage.objects for delete to authenticated using (bucket_id = 'calabazas');

-- ---------------------------------------------------------------------
-- 5. Vista de comprobación
--    Corre  select * from public.resumen_calabazas;  cuando quieras un
--    conteo rápido sin abrir la app.
-- ---------------------------------------------------------------------
create or replace view public.resumen_calabazas as
select
  temporada,
  tipo,
  count(*)                                          as piezas,
  count(*) filter (where estado = 'VENDIDA')        as vendidas,
  count(*) filter (where estado = 'EN ALMACÉN')     as en_almacen,
  count(*) filter (where estado = 'ASIGNADA')       as asignadas,
  sum(precio_venta) filter (where estado = 'VENDIDA') as ingreso
from public.piezas
group by temporada, tipo
order by temporada, tipo;

-- Listo. Si no salió ningún error en rojo, la base ya está creada.
