-- Update severity scale from 1-5 to 0-10
alter table public.efectos_secundarios drop constraint efectos_secundarios_severidad_check;
alter table public.efectos_secundarios add constraint efectos_secundarios_severidad_check check (severidad between 0 and 10);

-- RPC: link patient profile after invitation signup
-- Runs as security definer to bypass RLS and update pacientes.profile_id
create or replace function public.link_patient_profile(p_token uuid, p_paciente_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from public.invite_tokens
    where token = p_token
    and paciente_id = p_paciente_id
    and used = false
    and expires_at > now()
  ) then
    raise exception 'Token inválido o expirado';
  end if;

  update public.pacientes
  set profile_id = auth.uid()
  where id = p_paciente_id;
end;
$$;
