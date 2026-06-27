import { createClient } from '@/lib/supabase/server';
import Link from 'next/link';
import NuevoPacienteForm from './NuevoPacienteForm';
import PacienteAcciones from "./PacienteAcciones";

export default async function MedicoPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: pacientes } = await supabase
    .from('pacientes')
    .select('*')
    .eq('medico_id', user!.id)
    .order('created_at', { ascending: false });

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Mis pacientes</h1>
        <NuevoPacienteForm medicoId={user!.id} />
      </div>

      {pacientes && pacientes.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {pacientes.map((p) => (
            <div key={p.id}>
              <Link
              href={`/medico/paciente/${p.id}`}
              className="bg-white rounded-lg shadow p-5 hover:shadow-md transition-shadow"
            >
              <p className="font-semibold text-gray-900">{p.nombre}</p>
              <p className="text-sm text-gray-500 mt-1">{p.email}</p>
              {p.fecha_inicio_tratamiento && (
                <p className="text-xs text-gray-400 mt-2">
                  Inicio: {new Date(p.fecha_inicio_tratamiento).toLocaleDateString('es-AR')}
                </p>
              )}
            </Link>
              <PacienteAcciones pacienteId={p.id} nombre={p.nombre} email={p.email} />
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
          <p className="text-lg">No tenés pacientes aún.</p>
          <p className="text-sm mt-2">Usá el botón de arriba para invitar a tu primer paciente.</p>
        </div>
      )}
    </div>
  );
}
