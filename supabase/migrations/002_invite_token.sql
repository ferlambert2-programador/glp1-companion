-- Invite tokens for patient onboarding
create table public.invite_tokens (
  id uuid primary key default uuid_generate_v4(),
  token uuid not null unique default uuid_generate_v4(),
  medico_id uuid references public.profiles(id) on delete cascade not null,
  email_paciente text not null,
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  used boolean not null default false,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.invite_tokens enable row level security;

create policy "Medicos manage own invite tokens" on public.invite_tokens
  using (medico_id = auth.uid());

create policy "Anyone can read invite tokens" on public.invite_tokens for select
  using (true);
