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
