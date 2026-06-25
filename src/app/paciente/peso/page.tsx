'use client';

import { createClient } from '@/lib/supabase/client';
import { useState, useEffect } from 'react';
import PesoChart from '@/components/charts/PesoChart';
import type { RegistroPeso } from '@/lib/types';

export default function PesoPage() {
  const supabase = createClient();
  const [pesoKg, setPesoKg] = useState('');
  const [nota, setNota] = useState('');
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [registros, setRegistros] = useState<RegistroPeso[]>([]);
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
        .from('registros_peso')
        .select('*')
        .eq('paciente_id', paciente.id)
        .order('fecha', { ascending: true });

      setRegistros(data ?? []);
    }
    load();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!pacienteId) return;
    setLoading(true);

    await supabase.from('registros_peso').insert({
      paciente_id: pacienteId,
      peso_kg: parseFloat(pesoKg),
      fecha,
      nota: nota || null,
    });

    const { data } = await supabase
      .from('registros_peso')
      .select('*')
      .eq('paciente_id', pacienteId)
      .order('fecha', { ascending: true });

    setRegistros(data ?? []);
    setPesoKg('');
    setNota('');
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
    setLoading(false);
  }

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold text-gray-900">Registro de peso</h1>

      <form onSubmit={handleSubmit} className="bg-white shadow rounded-lg p-6 space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Peso (kg)</label>
            <input
              type="number"
              step="0.1"
              required
              value={pesoKg}
              onChange={(e) => setPesoKg(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="85.5"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Fecha</label>
            <input
              type="date"
              required
              value={fecha}
              onChange={(e) => setFecha(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Nota (opcional)</label>
          <input
            type="text"
            value={nota}
            onChange={(e) => setNota(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            placeholder="Ej: después del desayuno"
          />
        </div>

        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-2 rounded text-sm">
            Peso registrado correctamente.
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
        >
          {loading ? 'Guardando...' : 'Guardar peso'}
        </button>
      </form>

      {registros.length > 0 && (
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Evolución de peso</h2>
          <PesoChart data={registros} />
        </div>
      )}
    </div>
  );
}
