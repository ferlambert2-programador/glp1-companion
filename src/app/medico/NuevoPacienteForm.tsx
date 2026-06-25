'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface Props {
  medicoId: string;
}

export default function NuevoPacienteForm({ medicoId }: Props) {
  const router = useRouter();
  const supabase = createClient();
  const [open, setOpen] = useState(false);
  const [nombre, setNombre] = useState('');
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [inviteUrl, setInviteUrl] = useState('');
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');

    const token = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

    const { data: paciente, error: pacienteError } = await supabase
      .from('pacientes')
      .insert({ nombre, email, medico_id: medicoId })
      .select()
      .single();

    if (pacienteError || !paciente) {
      setError('Error al crear el paciente.');
      setLoading(false);
      return;
    }

    const { error: tokenError } = await supabase.from('invite_tokens').insert({
      token,
      medico_id: medicoId,
      email_paciente: email,
      paciente_id: paciente.id,
      expires_at: expiresAt,
    });

    if (tokenError) {
      setError('Error al generar el token de invitación.');
      setLoading(false);
      return;
    }

    const url = `${window.location.origin}/unirse/${token}`;
    setInviteUrl(url);
    setLoading(false);
    router.refresh();
  }

  function handleClose() {
    setOpen(false);
    setNombre('');
    setEmail('');
    setInviteUrl('');
    setError('');
  }

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 text-sm font-medium"
      >
        + Nuevo paciente
      </button>

      {open && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900">Invitar paciente</h2>
              <button onClick={handleClose} className="text-gray-400 hover:text-gray-600 text-xl leading-none">&times;</button>
            </div>

            {!inviteUrl ? (
              <form onSubmit={handleSubmit} className="space-y-4">
                {error && (
                  <div className="bg-red-50 border border-red-200 text-red-700 px-3 py-2 rounded text-sm">
                    {error}
                  </div>
                )}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Nombre del paciente</label>
                  <input
                    type="text"
                    required
                    value={nombre}
                    onChange={(e) => setNombre(e.target.value)}
                    className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
                    placeholder="Juan Pérez"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Email del paciente</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
                    placeholder="paciente@email.com"
                  />
                </div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
                >
                  {loading ? 'Generando invitación...' : 'Generar link de invitación'}
                </button>
              </form>
            ) : (
              <div className="space-y-4">
                <div className="bg-green-50 border border-green-200 rounded p-3">
                  <p className="text-sm text-green-700 font-medium mb-2">Paciente creado. Compartí este link:</p>
                  <p className="text-xs break-all text-gray-700 bg-white border rounded p-2">{inviteUrl}</p>
                </div>
                <button
                  onClick={() => navigator.clipboard.writeText(inviteUrl)}
                  className="w-full border border-gray-300 text-gray-700 py-2 px-4 rounded-md hover:bg-gray-50 text-sm"
                >
                  Copiar link
                </button>
                <p className="text-xs text-gray-500 text-center">El link expira en 7 días.</p>
                <button
                  onClick={handleClose}
                  className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 font-medium text-sm"
                >
                  Listo
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
