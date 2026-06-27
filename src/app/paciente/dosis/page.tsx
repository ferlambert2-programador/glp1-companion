'use client';

import { createClient } from '@/lib/supabase/client';
import { useState, useEffect } from 'react';
import type { RegistroDosis } from '@/lib/types';

const MEDICAMENTOS = ['Semaglutida (Obetide)', 'Semaglutida (Dutide)', 'Liraglutida (Victoza)', 'Dulaglutida (Trulicity)', 'Tirzepatida (Mounjaro)'];

export default function DosisPage() {
  const supabase = createClient();
  const [medicamento, setMedicamento] = useState(MEDICAMENTOS[0]);
  const [dosisMg, setDosisMg] = useState('');
  const [fechaAplicacion, setFechaAplicacion] = useState(new Date().toISOString().split('T')[0]);
  const [proximaDosis, setProximaDosis] = useState('');
  const [nota, setNota] = useState('');
  const [registros, setRegistros] = useState<RegistroDosis[]>([]);
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
        .from('registros_dosis')
        .select('*')
        .eq('paciente_id', paciente.id)
        .order('fecha_aplicacion', { ascending: false })
        .limit(10);

      setRegistros(data ?? []);
    }
    load();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!pacienteId) return;
    setLoading(true);

    await supabase.from('registros_dosis').insert({
      paciente_id: pacienteId,
      medicamento,
      dosis_mg: parseFloat(dosisMg),
      fecha_aplicacion: fechaAplicacion,
      proxima_dosis: proximaDosis || null,
      nota: nota || null,
    });

    const { data } = await supabase
      .from('registros_dosis')
      .select('*')
      .eq('paciente_id', pacienteId)
      .order('fecha_aplicacion', { ascending: false })
      .limit(10);

    setRegistros(data ?? []);
    setDosisMg('');
    setNota('');
    setProximaDosis('');
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
    setLoading(false);
  }

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold text-gray-900">Registro de dosis</h1>

      <form onSubmit={handleSubmit} className="bg-white shadow rounded-lg p-6 space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Medicamento</label>
          <select
            value={medicamento}
            onChange={(e) => setMedicamento(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
          >
            {MEDICAMENTOS.map((m) => (
              <option key={m} value={m}>{m}</option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Dosis (mg)</label>
            <input
              type="number"
              step="0.25"
              required
              value={dosisMg}
              onChange={(e) => setDosisMg(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="0.5"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Fecha de aplicación</label>
            <input
              type="date"
              required
              value={fechaAplicacion}
              onChange={(e) => setFechaAplicacion(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Próxima dosis (opcional)</label>
          <input
            type="date"
            value={proximaDosis}
            onChange={(e) => setProximaDosis(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Nota (opcional)</label>
          <input
            type="text"
            value={nota}
            onChange={(e) => setNota(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            placeholder="Ej: sitio de inyección, tolerancia..."
          />
        </div>

        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-2 rounded text-sm">
            Dosis registrada correctamente.
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50 font-medium"
        >
          {loading ? 'Guardando...' : 'Registrar dosis'}
        </button>
      </form>

      {registros.length > 0 && (
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Historial reciente</h2>
          <div className="space-y-3">
            {registros.map((r) => (
              <div key={r.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
                <div>
                  <p className="font-medium text-gray-800">{r.medicamento}</p>
                  <p className="text-sm text-gray-500">{r.dosis_mg} mg — {new Date(r.fecha_aplicacion).toLocaleDateString('es-AR')}</p>
                </div>
                {r.proxima_dosis && (
                  <span className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded">
                    Próxima: {new Date(r.proxima_dosis).toLocaleDateString('es-AR')}
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
