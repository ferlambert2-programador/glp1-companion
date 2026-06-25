'use client';

import { createClient } from '@/lib/supabase/client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

const MEDICAMENTOS = ['Semaglutida (Ozempic)', 'Semaglutida (Wegovy)', 'Liraglutida (Victoza)', 'Dulaglutida (Trulicity)', 'Tirzepatida (Mounjaro)'];

interface Props {
  params: { id: string };
}

export default function TratamientoPage({ params }: Props) {
  const router = useRouter();
  const supabase = createClient();
  const [medicamento, setMedicamento] = useState(MEDICAMENTOS[0]);
  const [dosisInicial, setDosisInicial] = useState('');
  const [dosisActual, setDosisActual] = useState('');
  const [objetivoPeso, setObjetivoPeso] = useState('');
  const [observaciones, setObservaciones] = useState('');
  const [tratamientoId, setTratamientoId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    async function load() {
      const { data } = await supabase
        .from('tratamientos')
        .select('*')
        .eq('paciente_id', params.id)
        .eq('activo', true)
        .single();

      if (data) {
        setTratamientoId(data.id);
        setMedicamento(data.medicamento);
        setDosisInicial(String(data.dosis_inicial_mg));
        setDosisActual(String(data.dosis_actual_mg));
        setObjetivoPeso(data.objetivo_peso_kg ? String(data.objetivo_peso_kg) : '');
        setObservaciones(data.observaciones ?? '');
      }
    }
    load();
  }, [params.id]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    const payload = {
      paciente_id: params.id,
      medicamento,
      dosis_inicial_mg: parseFloat(dosisInicial),
      dosis_actual_mg: parseFloat(dosisActual),
      objetivo_peso_kg: objetivoPeso ? parseFloat(objetivoPeso) : null,
      observaciones: observaciones || null,
      activo: true,
    };

    if (tratamientoId) {
      await supabase.from('tratamientos').update({ ...payload, updated_at: new Date().toISOString() }).eq('id', tratamientoId);
    } else {
      const { data } = await supabase.from('tratamientos').insert(payload).select().single();
      if (data) setTratamientoId(data.id);
    }

    setSuccess(true);
    setTimeout(() => {
      router.push(`/medico/paciente/${params.id}`);
    }, 1500);
    setLoading(false);
  }

  return (
    <div className="space-y-6">
      <div>
        <Link href={`/medico/paciente/${params.id}`} className="text-sm text-gray-500 hover:text-gray-700">
          ← Volver al paciente
        </Link>
        <h1 className="text-2xl font-bold text-gray-900 mt-1">Configurar tratamiento</h1>
      </div>

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
            <label className="block text-sm font-medium text-gray-700 mb-1">Dosis inicial (mg)</label>
            <input
              type="number"
              step="0.25"
              required
              value={dosisInicial}
              onChange={(e) => setDosisInicial(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="0.25"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Dosis actual (mg)</label>
            <input
              type="number"
              step="0.25"
              required
              value={dosisActual}
              onChange={(e) => setDosisActual(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="0.5"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Peso objetivo (kg, opcional)</label>
          <input
            type="number"
            step="0.5"
            value={objetivoPeso}
            onChange={(e) => setObjetivoPeso(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            placeholder="70"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Observaciones clínicas (opcional)</label>
          <textarea
            value={observaciones}
            onChange={(e) => setObservaciones(e.target.value)}
            rows={3}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            placeholder="Notas sobre el plan de titulación, contraindicaciones, etc."
          />
        </div>

        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-2 rounded text-sm">
            Tratamiento guardado. Redirigiendo...
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
        >
          {loading ? 'Guardando...' : 'Guardar tratamiento'}
        </button>
      </form>
    </div>
  );
}
