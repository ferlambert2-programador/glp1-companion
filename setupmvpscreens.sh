#!/usr/bin/env bash
# setup-mvp-screens.sh
# Aplica los cambios del MVP de pantallas sobre tu copia local del repo.
# Correr desde la raíz del proyecto: bash setup-mvp-screens.sh

set -e
cd "$(dirname "$0")"

echo "==> Creando rama claude/glp1-mvp-screens-zqwbcx..."
git checkout -b claude/glp1-mvp-screens-zqwbcx

echo "==> Escribiendo archivos..."

# ── 1. supabase/migrations/003_updates.sql ──────────────────────────────────
mkdir -p supabase/migrations
cat > supabase/migrations/003_updates.sql << 'HEREDOC'
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
HEREDOC

# ── 2. src/lib/types.ts ─────────────────────────────────────────────────────
cat > src/lib/types.ts << 'HEREDOC'
export type Role = 'medico' | 'paciente';

export interface Profile {
  id: string;
  email: string;
  nombre: string;
  role: Role;
  consentimiento_firmado: boolean;
  created_at: string;
}

export interface Paciente {
  id: string;
  profile_id: string;
  medico_id: string;
  nombre: string;
  email: string;
  fecha_inicio_tratamiento: string | null;
  created_at: string;
}

export interface RegistroPeso {
  id: string;
  paciente_id: string;
  peso_kg: number;
  fecha: string;
  nota: string | null;
  created_at: string;
}

export interface RegistroDosis {
  id: string;
  paciente_id: string;
  medicamento: string;
  dosis_mg: number;
  fecha_aplicacion: string;
  proxima_dosis: string | null;
  nota: string | null;
  created_at: string;
}

export interface EfectoSecundario {
  id: string;
  paciente_id: string;
  tipo: string;
  severidad: number; // 0-10
  fecha: string;
  descripcion: string | null;
  created_at: string;
}

export interface Tratamiento {
  id: string;
  paciente_id: string;
  medicamento: string;
  dosis_inicial_mg: number;
  dosis_actual_mg: number;
  objetivo_peso_kg: number | null;
  observaciones: string | null;
  activo: boolean;
  created_at: string;
  updated_at: string;
}

export interface InviteToken {
  id: string;
  token: string;
  medico_id: string;
  email_paciente: string;
  used: boolean;
  expires_at: string;
  created_at: string;
}
HEREDOC

# ── 3. src/app/paciente/efectos/page.tsx ────────────────────────────────────
cat > src/app/paciente/efectos/page.tsx << 'HEREDOC'
'use client';

import { createClient } from '@/lib/supabase/client';
import { useState, useEffect } from 'react';
import type { EfectoSecundario } from '@/lib/types';

const TIPOS_EFECTOS = [
  'Náuseas',
  'Vómitos',
  'Diarrea',
  'Constipación',
  'Reflujo',
  'Dolor abdominal',
  'Fatiga',
  'Otro',
];

function severidadLabel(v: number) {
  if (v === 0) return 'Nada';
  if (v <= 2) return 'Muy poco';
  if (v <= 4) return 'Poco';
  if (v <= 6) return 'Bastante';
  if (v <= 8) return 'Mucho';
  return 'Muy mal';
}

function severidadColor(v: number) {
  if (v === 0) return 'bg-gray-100 text-gray-600';
  if (v <= 2) return 'bg-green-100 text-green-700';
  if (v <= 4) return 'bg-yellow-100 text-yellow-700';
  if (v <= 6) return 'bg-orange-100 text-orange-700';
  if (v <= 8) return 'bg-red-100 text-red-700';
  return 'bg-red-200 text-red-800';
}

export default function EfectosPage() {
  const supabase = createClient();
  const [tipo, setTipo] = useState(TIPOS_EFECTOS[0]);
  const [severidad, setSeveridad] = useState(0);
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [descripcion, setDescripcion] = useState('');
  const [efectos, setEfectos] = useState<EfectoSecundario[]>([]);
  const [loading, setLoading] = useState(false);
  const [pacienteId, setPacienteId] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    async function load() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: paciente } = await supabase
        .from('pacientes')
        .select('id')
        .eq('profile_id', user.id)
        .single();

      if (!paciente) return;
      setPacienteId(paciente.id);

      const { data } = await supabase
        .from('efectos_secundarios')
        .select('*')
        .eq('paciente_id', paciente.id)
        .order('fecha', { ascending: false })
        .limit(10);

      setEfectos(data ?? []);
    }
    load();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!pacienteId) return;
    setLoading(true);

    await supabase.from('efectos_secundarios').insert({
      paciente_id: pacienteId,
      tipo,
      severidad,
      fecha,
      descripcion: descripcion || null,
    });

    const { data } = await supabase
      .from('efectos_secundarios')
      .select('*')
      .eq('paciente_id', pacienteId)
      .order('fecha', { ascending: false })
      .limit(10);

    setEfectos(data ?? []);
    setDescripcion('');
    setSeveridad(0);
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
    setLoading(false);
  }

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold text-gray-900">¿Cómo me siento?</h1>

      <form onSubmit={handleSubmit} className="bg-white shadow rounded-lg p-6 space-y-5">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">¿Qué sentiste?</label>
            <select
              value={tipo}
              onChange={(e) => setTipo(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-orange-400"
            >
              {TIPOS_EFECTOS.map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Fecha</label>
            <input
              type="date"
              required
              value={fecha}
              onChange={(e) => setFecha(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-orange-400"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            ¿Cuánto te molestó?{' '}
            <span className={`ml-1 px-2 py-0.5 rounded text-xs font-semibold ${severidadColor(severidad)}`}>
              {severidad} — {severidadLabel(severidad)}
            </span>
          </label>
          <input
            type="range"
            min={0}
            max={10}
            value={severidad}
            onChange={(e) => setSeveridad(parseInt(e.target.value))}
            className="w-full accent-orange-500"
          />
          <div className="flex justify-between text-xs text-gray-400 mt-1">
            <span>0 — Nada</span>
            <span>5 — Bastante</span>
            <span>10 — Muy mal</span>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Contanos más (opcional)</label>
          <textarea
            value={descripcion}
            onChange={(e) => setDescripcion(e.target.value)}
            rows={3}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-orange-400"
            placeholder="Ej: me pasó después de comer, duró unas horas..."
          />
        </div>

        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-2 rounded text-sm">
            Registrado correctamente.
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-orange-500 text-white py-2 px-4 rounded-md hover:bg-orange-600 disabled:opacity-50 font-medium"
        >
          {loading ? 'Guardando...' : 'Guardar'}
        </button>
      </form>

      {efectos.length > 0 && (
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Historial reciente</h2>
          <div className="space-y-3">
            {efectos.map((e) => (
              <div key={e.id} className="flex items-start justify-between py-2 border-b border-gray-100 last:border-0">
                <div>
                  <p className="font-medium text-gray-800">{e.tipo}</p>
                  <p className="text-sm text-gray-500">{new Date(e.fecha).toLocaleDateString('es-AR')}</p>
                  {e.descripcion && <p className="text-sm text-gray-600 mt-1">{e.descripcion}</p>}
                </div>
                <span className={`text-xs px-2 py-1 rounded font-medium ${severidadColor(e.severidad)}`}>
                  {e.severidad}/10 — {severidadLabel(e.severidad)}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
HEREDOC

# ── 4. src/app/unirse/[token]/UnirseForm.tsx ────────────────────────────────
cat > 'src/app/unirse/[token]/UnirseForm.tsx' << 'HEREDOC'
'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface Props {
  token: string;
  pacienteId: string;
  emailPaciente: string;
  nombrePaciente: string;
}

export default function UnirseForm({ token, pacienteId, emailPaciente, nombrePaciente }: Props) {
  const router = useRouter();
  const supabase = createClient();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (password !== confirmPassword) {
      setError('Las contraseñas no coinciden.');
      return;
    }
    if (password.length < 6) {
      setError('La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    setLoading(true);
    setError('');

    const { error: signUpError } = await supabase.auth.signUp({
      email: emailPaciente,
      password,
      options: {
        data: { nombre: nombrePaciente, role: 'paciente' },
      },
    });

    if (signUpError) {
      setError(signUpError.message);
      setLoading(false);
      return;
    }

    // Link the pre-created pacientes record to the new user profile
    const { error: linkError } = await supabase.rpc('link_patient_profile', {
      p_token: token,
      p_paciente_id: pacienteId,
    });

    if (linkError) {
      setError('Error al vincular tu cuenta. Contactá a tu médico.');
      setLoading(false);
      return;
    }

    await supabase
      .from('invite_tokens')
      .update({ used: true })
      .eq('token', token);

    router.push('/onboarding/consentimiento');
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="bg-white shadow rounded-lg p-8 space-y-6">
      <div className="bg-green-50 border border-green-200 rounded p-4">
        <p className="text-sm text-green-800">
          Hola <strong>{nombrePaciente}</strong>, tu médico te invitó a usar GLP-1 Companion
          para hacer seguimiento de tu tratamiento.
        </p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
          {error}
        </div>
      )}

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
        <input
          type="email"
          value={emailPaciente}
          disabled
          className="w-full border border-gray-200 rounded-md px-3 py-2 bg-gray-50 text-gray-500"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Elegí una contraseña</label>
        <input
          type="password"
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
          placeholder="Mínimo 6 caracteres"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Confirmá la contraseña</label>
        <input
          type="password"
          required
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
          className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
          placeholder="Repetí la contraseña"
        />
      </div>

      <button
        type="submit"
        disabled={loading}
        className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
      >
        {loading ? 'Creando cuenta...' : 'Crear mi cuenta'}
      </button>
    </form>
  );
}
HEREDOC

# ── 5. src/app/unirse/[token]/page.tsx ──────────────────────────────────────
cat > 'src/app/unirse/[token]/page.tsx' << 'HEREDOC'
import { createClient } from '@/lib/supabase/server';
import { notFound } from 'next/navigation';
import UnirseForm from './UnirseForm';

interface Props {
  params: { token: string };
}

export default async function UnirsePage({ params }: Props) {
  const supabase = createClient();

  const { data: invite } = await supabase
    .from('invite_tokens')
    .select('*, pacientes(nombre)')
    .eq('token', params.token)
    .eq('used', false)
    .single();

  if (!invite) notFound();

  const expired = new Date(invite.expires_at) < new Date();
  if (expired) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
        <div className="max-w-md w-full bg-white rounded-lg shadow p-8 text-center space-y-4">
          <h1 className="text-xl font-bold text-red-600">Invitación expirada</h1>
          <p className="text-gray-600">Este link de invitación ya no es válido. Pedile a tu médico que genere uno nuevo.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900">GLP-1 Companion</h1>
          <p className="mt-2 text-gray-600">
            Fuiste invitado/a a unirte como paciente
          </p>
        </div>
        <UnirseForm
          token={params.token}
          pacienteId={invite.paciente_id}
          emailPaciente={invite.email_paciente}
          nombrePaciente={(invite.pacientes as { nombre: string })?.nombre}
        />
      </div>
    </div>
  );
}
HEREDOC

# ── 6. src/app/medico/paciente/[id]/page.tsx ────────────────────────────────
mkdir -p 'src/app/medico/paciente/[id]'
cat > 'src/app/medico/paciente/[id]/page.tsx' << 'HEREDOC'
import { createClient } from '@/lib/supabase/server';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import PesoChart from '@/components/charts/PesoChart';

interface Props {
  params: { id: string };
}

export default async function MedicoPacientePage({ params }: Props) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: paciente } = await supabase
    .from('pacientes')
    .select('*')
    .eq('id', params.id)
    .eq('medico_id', user!.id)
    .single();

  if (!paciente) notFound();

  const [{ data: pesos }, { data: ultimosPesos }, { data: dosis }, { data: efectos }, { data: tratamiento }] =
    await Promise.all([
      supabase
        .from('registros_peso')
        .select('*')
        .eq('paciente_id', params.id)
        .order('fecha', { ascending: true }),
      supabase
        .from('registros_peso')
        .select('peso_kg, fecha, nota')
        .eq('paciente_id', params.id)
        .order('fecha', { ascending: false })
        .limit(5),
      supabase
        .from('registros_dosis')
        .select('*')
        .eq('paciente_id', params.id)
        .order('fecha_aplicacion', { ascending: false })
        .limit(5),
      supabase
        .from('efectos_secundarios')
        .select('*')
        .eq('paciente_id', params.id)
        .order('fecha', { ascending: false })
        .limit(5),
      supabase
        .from('tratamientos')
        .select('*')
        .eq('paciente_id', params.id)
        .eq('activo', true)
        .single(),
    ]);

  function severidadLabel(v: number) {
    if (v === 0) return 'Nada';
    if (v <= 2) return 'Muy poco';
    if (v <= 4) return 'Poco';
    if (v <= 6) return 'Bastante';
    if (v <= 8) return 'Mucho';
    return 'Muy mal';
  }
  function severidadColor(v: number) {
    if (v === 0) return 'text-gray-500';
    if (v <= 2) return 'text-green-600';
    if (v <= 4) return 'text-yellow-600';
    if (v <= 6) return 'text-orange-600';
    if (v <= 8) return 'text-red-600';
    return 'text-red-800';
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <Link href="/medico" className="text-sm text-gray-500 hover:text-gray-700">
            ← Mis pacientes
          </Link>
          <h1 className="text-2xl font-bold text-gray-900 mt-1">{paciente.nombre}</h1>
          <p className="text-sm text-gray-500">{paciente.email}</p>
        </div>
        <Link
          href={`/medico/paciente/${params.id}/tratamiento`}
          className="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 text-sm font-medium"
        >
          {tratamiento ? 'Editar tratamiento' : 'Configurar tratamiento'}
        </Link>
      </div>

      {tratamiento && (
        <div className="bg-white rounded-lg shadow p-5">
          <h2 className="text-lg font-semibold text-gray-800 mb-3">Tratamiento activo</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <p className="text-gray-500">Medicamento</p>
              <p className="font-medium">{tratamiento.medicamento}</p>
            </div>
            <div>
              <p className="text-gray-500">Dosis inicial</p>
              <p className="font-medium">{tratamiento.dosis_inicial_mg} mg</p>
            </div>
            <div>
              <p className="text-gray-500">Dosis actual</p>
              <p className="font-medium">{tratamiento.dosis_actual_mg} mg</p>
            </div>
            {tratamiento.objetivo_peso_kg && (
              <div>
                <p className="text-gray-500">Objetivo</p>
                <p className="font-medium">{tratamiento.objetivo_peso_kg} kg</p>
              </div>
            )}
          </div>
          {tratamiento.observaciones && (
            <p className="text-sm text-gray-600 mt-3 border-t pt-3">{tratamiento.observaciones}</p>
          )}
        </div>
      )}

      {pesos && pesos.length > 0 && (
        <div className="bg-white rounded-lg shadow p-5">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Evolución de peso</h2>
          <PesoChart data={pesos} />
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg shadow p-5">
          <h2 className="text-lg font-semibold text-gray-800 mb-3">Últimos pesos</h2>
          {ultimosPesos && ultimosPesos.length > 0 ? (
            <div className="space-y-2">
              {ultimosPesos.map((p, i) => (
                <div key={i} className="flex justify-between py-1 border-b border-gray-100 last:border-0 text-sm">
                  <span className="font-medium text-gray-800">{p.peso_kg} kg</span>
                  <span className="text-gray-400">{new Date(p.fecha).toLocaleDateString('es-AR')}</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-gray-400">Sin registros de peso.</p>
          )}
        </div>

        <div className="bg-white rounded-lg shadow p-5">
          <h2 className="text-lg font-semibold text-gray-800 mb-3">Últimas dosis</h2>
          {dosis && dosis.length > 0 ? (
            <div className="space-y-2">
              {dosis.map((d) => (
                <div key={d.id} className="flex justify-between py-1 border-b border-gray-100 last:border-0 text-sm">
                  <span className="text-gray-700">{d.medicamento} — {d.dosis_mg} mg</span>
                  <span className="text-gray-400">{new Date(d.fecha_aplicacion).toLocaleDateString('es-AR')}</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-gray-400">Sin registros de dosis.</p>
          )}
        </div>

        <div className="bg-white rounded-lg shadow p-5">
          <h2 className="text-lg font-semibold text-gray-800 mb-3">Efectos secundarios recientes</h2>
          {efectos && efectos.length > 0 ? (
            <div className="space-y-2">
              {efectos.map((e) => (
                <div key={e.id} className="flex justify-between py-1 border-b border-gray-100 last:border-0 text-sm">
                  <span className="text-gray-700">{e.tipo}</span>
                  <span className={`font-medium ${severidadColor(e.severidad)}`}>
                    {e.severidad}/10 — {severidadLabel(e.severidad)}
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-gray-400">Sin efectos reportados.</p>
          )}
        </div>
      </div>
    </div>
  );
}
HEREDOC

echo "==> Commiteando..."
git add \
  supabase/migrations/003_updates.sql \
  src/lib/types.ts \
  src/app/paciente/efectos/page.tsx \
  'src/app/unirse/[token]/UnirseForm.tsx' \
  'src/app/unirse/[token]/page.tsx' \
  'src/app/medico/paciente/[id]/page.tsx'

git commit -m "feat: MVP screens — patient views, doctor data, invite linking

- efectos page: 0-10 scale with plain language, updated types (constipación, reflujo)
- doctor patient view: add Últimos pesos column, efectos show 0-10 scale
- invite flow: call link_patient_profile RPC after signup to set pacientes.profile_id
- migration 003: severity constraint 0-10, link_patient_profile security-definer fn"

echo "==> Pusheando..."
git push -u origin claude/glp1-mvp-screens-zqwbcx

echo ""
echo "✓ Listo. Acordate de aplicar la migración en Supabase:"
echo "  Supabase Dashboard → SQL Editor → correr supabase/migrations/003_updates.sql"
