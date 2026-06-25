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
          emailPaciente={invite.email_paciente}
          nombrePaciente={(invite.pacientes as { nombre: string })?.nombre}
        />
      </div>
    </div>
  );
}
