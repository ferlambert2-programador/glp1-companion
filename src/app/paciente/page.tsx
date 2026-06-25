import { createClient } from '@/lib/supabase/server';
import Link from 'next/link';

export default async function PacientePage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: paciente } = await supabase
    .from('pacientes')
    .select('*, tratamientos(*)')
    .eq('profile_id', user!.id)
    .single();

  const { data: ultimoPeso } = await supabase
    .from('registros_peso')
    .select('peso_kg, fecha')
    .eq('paciente_id', paciente?.id)
    .order('fecha', { ascending: false })
    .limit(1)
    .single();

  const { data: ultimaDosis } = await supabase
    .from('registros_dosis')
    .select('medicamento, dosis_mg, fecha_aplicacion, proxima_dosis')
    .eq('paciente_id', paciente?.id)
    .order('fecha_aplicacion', { ascending: false })
    .limit(1)
    .single();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Mi seguimiento</h1>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white rounded-lg shadow p-5 space-y-1">
          <p className="text-xs text-gray-500 uppercase tracking-wide">Último peso</p>
          <p className="text-2xl font-bold text-gray-900">
            {ultimoPeso ? `${ultimoPeso.peso_kg} kg` : '—'}
          </p>
          {ultimoPeso && (
            <p className="text-xs text-gray-400">
              {new Date(ultimoPeso.fecha).toLocaleDateString('es-AR')}
            </p>
          )}
        </div>

        <div className="bg-white rounded-lg shadow p-5 space-y-1">
          <p className="text-xs text-gray-500 uppercase tracking-wide">Última dosis</p>
          <p className="text-lg font-bold text-gray-900">
            {ultimaDosis ? `${ultimaDosis.dosis_mg} mg` : '—'}
          </p>
          {ultimaDosis && (
            <p className="text-xs text-gray-400">{ultimaDosis.medicamento}</p>
          )}
        </div>

        <div className="bg-white rounded-lg shadow p-5 space-y-1">
          <p className="text-xs text-gray-500 uppercase tracking-wide">Próxima dosis</p>
          <p className="text-lg font-bold text-gray-900">
            {ultimaDosis?.proxima_dosis
              ? new Date(ultimaDosis.proxima_dosis).toLocaleDateString('es-AR')
              : '—'}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Link
          href="/paciente/peso"
          className="bg-green-600 text-white rounded-lg p-4 text-center hover:bg-green-700"
        >
          <p className="font-semibold">Registrar peso</p>
        </Link>
        <Link
          href="/paciente/dosis"
          className="bg-blue-600 text-white rounded-lg p-4 text-center hover:bg-blue-700"
        >
          <p className="font-semibold">Registrar dosis</p>
        </Link>
        <Link
          href="/paciente/efectos"
          className="bg-orange-500 text-white rounded-lg p-4 text-center hover:bg-orange-600"
        >
          <p className="font-semibold">Reportar efecto</p>
        </Link>
      </div>
    </div>
  );
}
