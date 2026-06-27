#!/bin/bash
# =============================================================
# Script para aplicar los cambios de glp1-companion localmente
# y pushear a GitHub desde tu máquina.
#
# USO:
#   1. Cloná el repo o asegurate de tener la rama main actualizada
#   2. Corré: bash aplicar-cambios-local.sh
# =============================================================

set -e

BRANCH="claude/glp1-companion-fixes-90irj1"

echo ""
echo "=== Creando/cambiando a la rama $BRANCH ==="
git fetch origin main 2>/dev/null || true
git checkout -B "$BRANCH" origin/main 2>/dev/null || git checkout -B "$BRANCH"

echo ""
echo "=== Aplicando cambio 1/4: Obetide/Dutide en dosis del paciente ==="
FILE="src/app/paciente/dosis/page.tsx"
sed -i "s/Semaglutida (Ozempic)/Semaglutida (Obetide)/g" "$FILE"
sed -i "s/Semaglutida (Wegovy)/Semaglutida (Dutide)/g" "$FILE"
echo "  OK: $FILE"

echo ""
echo "=== Aplicando cambio 2/4: Obetide/Dutide en tratamiento del médico ==="
FILE="src/app/medico/paciente/[id]/tratamiento/page.tsx"
sed -i "s/Semaglutida (Ozempic)/Semaglutida (Obetide)/g" "$FILE"
sed -i "s/Semaglutida (Wegovy)/Semaglutida (Dutide)/g" "$FILE"
echo "  OK: $FILE"

echo ""
echo "=== Aplicando cambio 3/4: Crear EditarPacienteModal.tsx ==="
cat > src/app/medico/EditarPacienteModal.tsx << 'ENDOFFILE'
'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface Props {
  pacienteId: string;
  nombreActual: string;
  emailActual: string;
  onClose: () => void;
}

export default function EditarPacienteModal({ pacienteId, nombreActual, emailActual, onClose }: Props) {
  const router = useRouter();
  const supabase = createClient();
  const [nombre, setNombre] = useState(nombreActual);
  const [email, setEmail] = useState(emailActual);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');

    const { error: updateError } = await supabase
      .from('pacientes')
      .update({ nombre, email })
      .eq('id', pacienteId);

    if (updateError) {
      setError('Error al actualizar los datos del paciente.');
      setLoading(false);
      return;
    }

    router.refresh();
    onClose();
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 px-4">
      <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-md space-y-4">
        <h2 className="text-lg font-semibold text-gray-900">Editar paciente</h2>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-2 rounded text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Nombre</label>
            <input
              type="text"
              required
              value={nombre}
              onChange={(e) => setNombre(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 border border-gray-300 text-gray-700 py-2 px-4 rounded-md hover:bg-gray-50 font-medium"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
            >
              {loading ? 'Guardando...' : 'Guardar'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
ENDOFFILE
echo "  OK: src/app/medico/EditarPacienteModal.tsx"

echo ""
echo "=== Aplicando cambio 4/4: Crear PacienteAcciones.tsx ==="
cat > src/app/medico/PacienteAcciones.tsx << 'ENDOFFILE'
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
ENDOFFILE
echo "  OK: src/app/medico/PacienteAcciones.tsx"

echo ""
echo "=== Actualizando src/app/medico/page.tsx ==="
python3 - << 'PYEOF'
import re

path = "src/app/medico/page.tsx"
with open(path, "r") as f:
    content = f.read()

# Add import
old_import = "import NuevoPacienteForm from './NuevoPacienteForm';"
new_import = "import NuevoPacienteForm from './NuevoPacienteForm';\nimport PacienteAcciones from './PacienteAcciones';"
content = content.replace(old_import, new_import, 1)

# Replace patient card list
old_card = """          {pacientes.map((p) => (
            <Link
              key={p.id}
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
          ))}"""

new_card = """          {pacientes.map((p) => (
            <div key={p.id} className="bg-white rounded-lg shadow p-5 hover:shadow-md transition-shadow">
              <Link href={`/medico/paciente/${p.id}`} className="block">
                <p className="font-semibold text-gray-900">{p.nombre}</p>
                <p className="text-sm text-gray-500 mt-1">{p.email}</p>
                {p.fecha_inicio_tratamiento && (
                  <p className="text-xs text-gray-400 mt-2">
                    Inicio: {new Date(p.fecha_inicio_tratamiento).toLocaleDateString('es-AR')}
                  </p>
                )}
              </Link>
              <div className="mt-3 pt-3 border-t border-gray-100">
                <PacienteAcciones pacienteId={p.id} nombre={p.nombre} email={p.email} />
              </div>
            </div>
          ))}"""

content = content.replace(old_card, new_card, 1)

with open(path, "w") as f:
    f.write(content)

print("  OK: " + path)
PYEOF

echo ""
echo "=== Actualizando src/app/medico/paciente/[id]/page.tsx ==="
python3 - << 'PYEOF'
path = "src/app/medico/paciente/[id]/page.tsx"
with open(path, "r") as f:
    content = f.read()

# Add import
old_import = "import PesoChart from '@/components/charts/PesoChart';"
new_import = "import PesoChart from '@/components/charts/PesoChart';\nimport PacienteAcciones from '@/app/medico/PacienteAcciones';"
content = content.replace(old_import, new_import, 1)

# Add actions under patient email
old_header = """          <h1 className="text-2xl font-bold text-gray-900 mt-1">{paciente.nombre}</h1>
          <p className="text-sm text-gray-500">{paciente.email}</p>
        </div>"""
new_header = """          <h1 className="text-2xl font-bold text-gray-900 mt-1">{paciente.nombre}</h1>
          <p className="text-sm text-gray-500">{paciente.email}</p>
          <div className="mt-2">
            <PacienteAcciones
              pacienteId={paciente.id}
              nombre={paciente.nombre}
              email={paciente.email}
              redirectOnDelete
            />
          </div>
        </div>"""
content = content.replace(old_header, new_header, 1)

with open(path, "w") as f:
    f.write(content)

print("  OK: " + path)
PYEOF

echo ""
echo "=== Commiteando cambios ==="
git add \
  src/app/paciente/dosis/page.tsx \
  src/app/medico/paciente/[id]/tratamiento/page.tsx \
  src/app/medico/EditarPacienteModal.tsx \
  src/app/medico/PacienteAcciones.tsx \
  src/app/medico/page.tsx \
  "src/app/medico/paciente/[id]/page.tsx"

git commit -m "feat: marcas argentinas (Obetide/Dutide), editar/eliminar paciente

- Reemplaza Ozempic/Wegovy por Obetide/Dutide en lista de medicamentos
- Agrega botones Editar y Eliminar (con confirmación) en lista de
  pacientes y en vista individual del paciente
- El flujo /unirse/[token] ya permitía registro directo — verificado"

echo ""
echo "=== Pusheando a GitHub ==="
git push -u origin "$BRANCH"

echo ""
echo "============================================"
echo " LISTO. Cambios pusheados correctamente."
echo " Rama: $BRANCH"
echo " Commit: $(git rev-parse HEAD)"
echo "============================================"
