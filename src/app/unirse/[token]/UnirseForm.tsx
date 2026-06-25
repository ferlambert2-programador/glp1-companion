'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface Props {
  token: string;
  emailPaciente: string;
  nombrePaciente: string;
}

export default function UnirseForm({ token, emailPaciente, nombrePaciente }: Props) {
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
