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

  const [{ data: pesos }, { data: dosis }, { data: efectos }, { data: tratamiento }] =
    await Promise.all([
      supabase
        .from('registros_peso')
        .select('*')
        .eq('paciente_id', params.id)
        .order('fecha', { ascending: true }),
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

  const severidadLabel = ['', 'Leve', 'Leve-mod.', 'Moderado', 'Mod.-severo', 'Severo'];
  const severidadColor = ['', 'text-green-600', 'text-yellow-600', 'text-orange-600', 'text-red-600', 'text-red-800'];

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

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
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
                  <span className={`font-medium ${severidadColor[e.severidad]}`}>
                    {severidadLabel[e.severidad]}
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
