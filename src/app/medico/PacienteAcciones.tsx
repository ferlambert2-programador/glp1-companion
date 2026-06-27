'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import EditarPacienteModal from './EditarPacienteModal';

interface Props {
  pacienteId: string;
  nombre: string;
  email: string;
  redirectOnDelete?: boolean;
}

export default function PacienteAcciones({ pacienteId, nombre, email, redirectOnDelete }: Props) {
  const router = useRouter();
  const supabase = createClient();
  const [editOpen, setEditOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  async function handleDelete() {
    setDeleting(true);
    await supabase.from('pacientes').delete().eq('id', pacienteId);
    if (redirectOnDelete) {
      router.push('/medico');
    } else {
      router.refresh();
    }
  }

  return (
    <>
      <div className="flex gap-2" onClick={(e) => e.preventDefault()}>
        <button
          onClick={() => setEditOpen(true)}
          className="text-xs bg-gray-100 hover:bg-gray-200 text-gray-700 px-2 py-1 rounded font-medium"
        >
          Editar
        </button>
        <button
          onClick={() => setConfirmDelete(true)}
          className="text-xs bg-red-50 hover:bg-red-100 text-red-600 px-2 py-1 rounded font-medium"
        >
          Eliminar
        </button>
      </div>

      {editOpen && (
        <EditarPacienteModal
          pacienteId={pacienteId}
          nombreActual={nombre}
          emailActual={email}
          onClose={() => setEditOpen(false)}
        />
      )}

      {confirmDelete && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 px-4" onClick={(e) => e.preventDefault()}>
          <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-sm space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">Eliminar paciente</h2>
            <p className="text-sm text-gray-600">
              ¿Confirmás que querés eliminar a <strong>{nombre}</strong>? Esta acción no se puede deshacer.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setConfirmDelete(false)}
                disabled={deleting}
                className="flex-1 border border-gray-300 text-gray-700 py-2 px-4 rounded-md hover:bg-gray-50 font-medium"
              >
                Cancelar
              </button>
              <button
                onClick={handleDelete}
                disabled={deleting}
                className="flex-1 bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 disabled:opacity-50 font-medium"
              >
                {deleting ? 'Eliminando...' : 'Eliminar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
