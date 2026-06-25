'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function ConsentimientoPage() {
  const router = useRouter();
  const supabase = createClient();
  const [aceptado, setAceptado] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleAceptar() {
    if (!aceptado) return;
    setLoading(true);

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      router.push('/login');
      return;
    }

    await supabase
      .from('profiles')
      .update({ consentimiento_firmado: true })
      .eq('id', user.id);

    router.push('/');
    router.refresh();
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-2xl w-full space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900">Consentimiento Informado</h1>
          <p className="mt-2 text-gray-600">Por favor leé y aceptá los términos antes de continuar</p>
        </div>

        <div className="bg-white shadow rounded-lg p-8 space-y-6">
          <div className="prose max-w-none text-gray-700 text-sm space-y-4 h-64 overflow-y-auto border border-gray-200 rounded p-4">
            <h2 className="font-semibold text-gray-900">Términos de uso y privacidad</h2>
            <p>
              GLP-1 Companion es una herramienta de seguimiento diseñada para apoyar el
              tratamiento con agonistas del receptor GLP-1. Esta aplicación <strong>no reemplaza</strong> la
              consulta médica profesional.
            </p>
            <p>
              <strong>Datos que recopilamos:</strong> peso corporal, dosis de medicación,
              efectos secundarios reportados y datos de perfil básicos.
            </p>
            <p>
              <strong>Uso de los datos:</strong> Los datos son utilizados exclusivamente para
              el seguimiento de tu tratamiento por parte de tu médico tratante. No compartimos
              información con terceros sin tu consentimiento explícito.
            </p>
            <p>
              <strong>Almacenamiento:</strong> Toda la información se almacena de forma segura
              con cifrado en tránsito y en reposo. Podés solicitar la eliminación de tus datos
              en cualquier momento.
            </p>
            <p>
              <strong>Responsabilidad médica:</strong> Las decisiones de tratamiento son
              responsabilidad exclusiva de tu médico. Esta aplicación es solo una herramienta
              de registro y seguimiento.
            </p>
            <p>
              Al aceptar estos términos, confirmás que entendés el propósito de la aplicación
              y autorizás el procesamiento de tus datos de salud para los fines descritos.
            </p>
          </div>

          <label className="flex items-start gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={aceptado}
              onChange={(e) => setAceptado(e.target.checked)}
              className="mt-1 h-4 w-4 text-green-600 rounded border-gray-300"
            />
            <span className="text-sm text-gray-700">
              He leído y acepto los términos de uso y la política de privacidad. Entiendo que
              mis datos de salud serán procesados para el seguimiento de mi tratamiento.
            </span>
          </label>

          <button
            onClick={handleAceptar}
            disabled={!aceptado || loading}
            className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
          >
            {loading ? 'Procesando...' : 'Aceptar y continuar'}
          </button>
        </div>
      </div>
    </div>
  );
}
