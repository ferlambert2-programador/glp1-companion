-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles table (extends Supabase auth.users)
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text not null,
  nombre text not null,
  role text not null check (role in ('medico', 'paciente')),
  consentimiento_firmado boolean not null default false,
  created_at timestamptz not null default now()
);

-- Auto-create profile on user signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, nombre, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'nombre', ''),
    coalesce(new.raw_user_meta_data->>'role', 'paciente')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Pacientes
create table public.pacientes (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid references public.profiles(id) on delete set null,
  medico_id uuid references public.profiles(id) on delete cascade not null,
  nombre text not null,
  email text not null,
  fecha_inicio_tratamiento date,
  created_at timestamptz not null default now()
);

-- Registros de peso
create table public.registros_peso (
  id uuid primary key default uuid_generate_v4(),
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  peso_kg numeric(5,2) not null,
  fecha date not null,
  nota text,
  created_at timestamptz not null default now()
);

-- Registros de dosis
create table public.registros_dosis (
  id uuid primary key default uuid_generate_v4(),
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  medicamento text not null,
  dosis_mg numeric(6,3) not null,
  fecha_aplicacion date not null,
  proxima_dosis date,
  nota text,
  created_at timestamptz not null default now()
);

-- Efectos secundarios
create table public.efectos_secundarios (
  id uuid primary key default uuid_generate_v4(),
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  tipo text not null,
  severidad smallint not null check (severidad between 1 and 5),
  fecha date not null,
  descripcion text,
  created_at timestamptz not null default now()
);

-- Tratamientos
create table public.tratamientos (
  id uuid primary key default uuid_generate_v4(),
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  medicamento text not null,
  dosis_inicial_mg numeric(6,3) not null,
  dosis_actual_mg numeric(6,3) not null,
  objetivo_peso_kg numeric(5,2),
  observaciones text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.pacientes enable row level security;
alter table public.registros_peso enable row level security;
alter table public.registros_dosis enable row level security;
alter table public.efectos_secundarios enable row level security;
alter table public.tratamientos enable row level security;

-- Profiles policies
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

create policy "Medicos can view patient profiles" on public.profiles for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.profile_id = profiles.id
      and pacientes.medico_id = auth.uid()
    )
  );

-- Pacientes policies
create policy "Medicos manage own patients" on public.pacientes
  using (medico_id = auth.uid());

create policy "Pacientes view own record" on public.pacientes for select
  using (profile_id = auth.uid());

-- Registros peso policies
create policy "Pacientes manage own peso" on public.registros_peso
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = registros_peso.paciente_id
      and pacientes.profile_id = auth.uid()
    )
  );

create policy "Medicos view patient peso" on public.registros_peso for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = registros_peso.paciente_id
      and pacientes.medico_id = auth.uid()
    )
  );

-- Registros dosis policies
create policy "Pacientes manage own dosis" on public.registros_dosis
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = registros_dosis.paciente_id
      and pacientes.profile_id = auth.uid()
    )
  );

create policy "Medicos view patient dosis" on public.registros_dosis for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = registros_dosis.paciente_id
      and pacientes.medico_id = auth.uid()
    )
  );

-- Efectos secundarios policies
create policy "Pacientes manage own efectos" on public.efectos_secundarios
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = efectos_secundarios.paciente_id
      and pacientes.profile_id = auth.uid()
    )
  );

create policy "Medicos view patient efectos" on public.efectos_secundarios for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = efectos_secundarios.paciente_id
      and pacientes.medico_id = auth.uid()
    )
  );

-- Tratamientos policies
create policy "Medicos manage tratamientos" on public.tratamientos
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = tratamientos.paciente_id
      and pacientes.medico_id = auth.uid()
    )
  );

create policy "Pacientes view own tratamientos" on public.tratamientos for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = tratamientos.paciente_id
      and pacientes.profile_id = auth.uid()
    )
  );
