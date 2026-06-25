#!/usr/bin/env bash
# setup-glp1-companion.sh
# Corré este script dentro del directorio raíz de tu repo vacío:
#   git clone https://github.com/ferlambert2-programador/glp1-companion.git
#   cd glp1-companion
#   bash setup-glp1-companion.sh

set -euo pipefail

echo "→ Creando estructura de directorios..."
mkdir -p src/app/\(auth\)/login
mkdir -p src/app/\(auth\)/registro
mkdir -p src/app/onboarding/consentimiento
mkdir -p src/app/paciente/peso
mkdir -p src/app/paciente/dosis
mkdir -p src/app/paciente/efectos
mkdir -p src/app/medico/paciente/\[id\]/tratamiento
mkdir -p "src/app/unirse/[token]"
mkdir -p src/components/charts
mkdir -p src/lib/supabase
mkdir -p supabase/migrations

echo "→ Escribiendo archivos raíz..."

cat > .env.local.example << 'HEREDOC'
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
NEXT_PUBLIC_APP_URL=http://localhost:3000
HEREDOC

cat > next.config.mjs << 'HEREDOC'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverActions: {
      allowedOrigins: ['localhost:3000'],
    },
  },
};

export default nextConfig;
HEREDOC

cat > package.json << 'HEREDOC'
{
  "name": "glp1-companion",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@supabase/ssr": "^0.5.1",
    "@supabase/supabase-js": "^2.44.4",
    "next": "14.2.5",
    "react": "^18",
    "react-dom": "^18",
    "recharts": "^2.12.7"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.0.1",
    "eslint": "^8",
    "eslint-config-next": "14.2.5",
    "postcss": "^8",
    "tailwindcss": "^3.4.1",
    "typescript": "^5"
  }
}
HEREDOC

cat > postcss.config.js << 'HEREDOC'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
HEREDOC

cat > tailwind.config.ts << 'HEREDOC'
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0fdf4',
          100: '#dcfce7',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
        },
      },
    },
  },
  plugins: [],
};

export default config;
HEREDOC

cat > tsconfig.json << 'HEREDOC'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
HEREDOC

echo "→ src/middleware.ts"
cat > src/middleware.ts << 'HEREDOC'
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          );
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { pathname } = request.nextUrl;

  const publicPaths = ['/login', '/registro', '/unirse'];
  const isPublic = publicPaths.some((p) => pathname.startsWith(p));

  if (!user && !isPublic) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  if (user && (pathname === '/login' || pathname === '/registro')) {
    return NextResponse.redirect(new URL('/', request.url));
  }

  return supabaseResponse;
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
HEREDOC

echo "→ src/lib/types.ts"
cat > src/lib/types.ts << 'HEREDOC'
export type Role = 'medico' | 'paciente';

export interface Profile {
  id: string;
  email: string;
  nombre: string;
  role: Role;
  consentimiento_firmado: boolean;
  created_at: string;
}

export interface Paciente {
  id: string;
  profile_id: string;
  medico_id: string;
  nombre: string;
  email: string;
  fecha_inicio_tratamiento: string | null;
  created_at: string;
}

export interface RegistroPeso {
  id: string;
  paciente_id: string;
  peso_kg: number;
  fecha: string;
  nota: string | null;
  created_at: string;
}

export interface RegistroDosis {
  id: string;
  paciente_id: string;
  medicamento: string;
  dosis_mg: number;
  fecha_aplicacion: string;
  proxima_dosis: string | null;
  nota: string | null;
  created_at: string;
}

export interface EfectoSecundario {
  id: string;
  paciente_id: string;
  tipo: string;
  severidad: 1 | 2 | 3 | 4 | 5;
  fecha: string;
  descripcion: string | null;
  created_at: string;
}

export interface Tratamiento {
  id: string;
  paciente_id: string;
  medicamento: string;
  dosis_inicial_mg: number;
  dosis_actual_mg: number;
  objetivo_peso_kg: number | null;
  observaciones: string | null;
  activo: boolean;
  created_at: string;
  updated_at: string;
}

export interface InviteToken {
  id: string;
  token: string;
  medico_id: string;
  email_paciente: string;
  used: boolean;
  expires_at: string;
  created_at: string;
}
HEREDOC

echo "→ src/lib/supabase/client.ts"
cat > src/lib/supabase/client.ts << 'HEREDOC'
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
HEREDOC

echo "→ src/lib/supabase/server.ts"
cat > src/lib/supabase/server.ts << 'HEREDOC'
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export function createClient() {
  const cookieStore = cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Server Component — cookies set by middleware
          }
        },
      },
    }
  );
}
HEREDOC

echo "→ src/app/globals.css"
cat > src/app/globals.css << 'HEREDOC'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --foreground-rgb: 0, 0, 0;
  --background-rgb: 249, 250, 251;
}

body {
  color: rgb(var(--foreground-rgb));
  background: rgb(var(--background-rgb));
}
HEREDOC

echo "→ src/app/layout.tsx"
cat > src/app/layout.tsx << 'HEREDOC'
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'GLP-1 Companion',
  description: 'Seguimiento inteligente de tratamiento GLP-1',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
HEREDOC

echo "→ src/app/page.tsx"
cat > src/app/page.tsx << 'HEREDOC'
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';

export default async function Home() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role, consentimiento_firmado')
    .eq('id', user.id)
    .single();

  if (!profile) {
    redirect('/login');
  }

  if (!profile.consentimiento_firmado) {
    redirect('/onboarding/consentimiento');
  }

  if (profile.role === 'medico') {
    redirect('/medico');
  }

  redirect('/paciente');
}
HEREDOC

echo "→ src/app/(auth)/login/page.tsx"
cat > 'src/app/(auth)/login/page.tsx' << 'HEREDOC'
'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function LoginPage() {
  const router = useRouter();
  const supabase = createClient();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');

    const { error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      setError('Credenciales inválidas. Verificá tu email y contraseña.');
      setLoading(false);
      return;
    }

    router.push('/');
    router.refresh();
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900">GLP-1 Companion</h1>
          <p className="mt-2 text-gray-600">Iniciá sesión en tu cuenta</p>
        </div>

        <form onSubmit={handleSubmit} className="bg-white shadow rounded-lg p-8 space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Email
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="tu@email.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Contraseña
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
          >
            {loading ? 'Ingresando...' : 'Ingresar'}
          </button>

          <p className="text-center text-sm text-gray-600">
            ¿No tenés cuenta?{' '}
            <Link href="/registro" className="text-green-600 hover:underline">
              Registrate
            </Link>
          </p>
        </form>
      </div>
    </div>
  );
}
HEREDOC

echo "→ src/app/(auth)/registro/page.tsx"
cat > 'src/app/(auth)/registro/page.tsx' << 'HEREDOC'
'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function RegistroPage() {
  const router = useRouter();
  const supabase = createClient();
  const [nombre, setNombre] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');

    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { nombre, role: 'medico' },
      },
    });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    router.push('/onboarding/consentimiento');
    router.refresh();
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900">GLP-1 Companion</h1>
          <p className="mt-2 text-gray-600">Crear cuenta de médico</p>
        </div>

        <form onSubmit={handleSubmit} className="bg-white shadow rounded-lg p-8 space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nombre completo
            </label>
            <input
              type="text"
              required
              value={nombre}
              onChange={(e) => setNombre(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="Dr. Juan García"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Email
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="doctor@email.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Contraseña
            </label>
            <input
              type="password"
              required
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="Mínimo 6 caracteres"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
          >
            {loading ? 'Creando cuenta...' : 'Crear cuenta'}
          </button>

          <p className="text-center text-sm text-gray-600">
            ¿Ya tenés cuenta?{' '}
            <Link href="/login" className="text-green-600 hover:underline">
              Ingresá
            </Link>
          </p>
        </form>
      </div>
    </div>
  );
}
HEREDOC

echo "→ src/app/onboarding/consentimiento/page.tsx"
cat > src/app/onboarding/consentimiento/page.tsx << 'HEREDOC'
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
HEREDOC

echo "→ src/app/paciente/layout.tsx"
cat > src/app/paciente/layout.tsx << 'HEREDOC'
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';
import Link from 'next/link';

export default async function PacienteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  const { data: profile } = await supabase
    .from('profiles')
    .select('nombre, role')
    .eq('id', user.id)
    .single();

  if (profile?.role !== 'paciente') redirect('/medico');

  async function signOut() {
    'use server';
    const supabase = createClient();
    await supabase.auth.signOut();
    redirect('/login');
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b border-gray-200 px-4 py-3">
        <div className="max-w-2xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-6">
            <span className="font-bold text-green-700">GLP-1</span>
            <Link href="/paciente" className="text-sm text-gray-600 hover:text-gray-900">Inicio</Link>
            <Link href="/paciente/peso" className="text-sm text-gray-600 hover:text-gray-900">Peso</Link>
            <Link href="/paciente/dosis" className="text-sm text-gray-600 hover:text-gray-900">Dosis</Link>
            <Link href="/paciente/efectos" className="text-sm text-gray-600 hover:text-gray-900">Efectos</Link>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-sm text-gray-500">{profile?.nombre}</span>
            <form action={signOut}>
              <button type="submit" className="text-sm text-red-500 hover:text-red-700">
                Salir
              </button>
            </form>
          </div>
        </div>
      </nav>
      <main className="max-w-2xl mx-auto px-4 py-8">{children}</main>
    </div>
  );
}
HEREDOC

echo "→ src/app/paciente/page.tsx"
cat > src/app/paciente/page.tsx << 'HEREDOC'
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
HEREDOC

echo "→ src/app/paciente/peso/page.tsx"
cat > src/app/paciente/peso/page.tsx << 'HEREDOC'
'use client';

import { createClient } from '@/lib/supabase/client';
import { useState, useEffect } from 'react';
import PesoChart from '@/components/charts/PesoChart';
import type { RegistroPeso } from '@/lib/types';

export default function PesoPage() {
  const supabase = createClient();
  const [pesoKg, setPesoKg] = useState('');
  const [nota, setNota] = useState('');
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [registros, setRegistros] = useState<RegistroPeso[]>([]);
  const [loading, setLoading] = useState(false);
  const [pacienteId, setPacienteId] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    async function load() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: paciente } = await supabase
        .from('pacientes')
        .select('id')
        .eq('profile_id', user.id)
        .single();

      if (!paciente) return;
      setPacienteId(paciente.id);

      const { data } = await supabase
        .from('registros_peso')
        .select('*')
        .eq('paciente_id', paciente.id)
        .order('fecha', { ascending: true });

      setRegistros(data ?? []);
    }
    load();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!pacienteId) return;
    setLoading(true);

    await supabase.from('registros_peso').insert({
      paciente_id: pacienteId,
      peso_kg: parseFloat(pesoKg),
      fecha,
      nota: nota || null,
    });

    const { data } = await supabase
      .from('registros_peso')
      .select('*')
      .eq('paciente_id', pacienteId)
      .order('fecha', { ascending: true });

    setRegistros(data ?? []);
    setPesoKg('');
    setNota('');
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
    setLoading(false);
  }

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold text-gray-900">Registro de peso</h1>

      <form onSubmit={handleSubmit} className="bg-white shadow rounded-lg p-6 space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Peso (kg)</label>
            <input
              type="number"
              step="0.1"
              required
              value={pesoKg}
              onChange={(e) => setPesoKg(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="85.5"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Fecha</label>
            <input
              type="date"
              required
              value={fecha}
              onChange={(e) => setFecha(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Nota (opcional)</label>
          <input
            type="text"
            value={nota}
            onChange={(e) => setNota(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            placeholder="Ej: después del desayuno"
          />
        </div>

        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-2 rounded text-sm">
            Peso registrado correctamente.
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 font-medium"
        >
          {loading ? 'Guardando...' : 'Guardar peso'}
        </button>
      </form>

      {registros.length > 0 && (
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Evolución de peso</h2>
          <PesoChart data={registros} />
        </div>
      )}
    </div>
  );
}
HEREDOC

echo "→ src/app/paciente/dosis/page.tsx"
cat > src/app/paciente/dosis/page.tsx << 'HEREDOC'
'use client';

import { createClient } from '@/lib/supabase/client';
import { useState, useEffect } from 'react';
import type { RegistroDosis } from '@/lib/types';

const MEDICAMENTOS = ['Semaglutida (Ozempic)', 'Semaglutida (Wegovy)', 'Liraglutida (Victoza)', 'Dulaglutida (Trulicity)', 'Tirzepatida (Mounjaro)'];

export default function DosisPage() {
  const supabase = createClient();
  const [medicamento, setMedicamento] = useState(MEDICAMENTOS[0]);
  const [dosisMg, setDosisMg] = useState('');
  const [fechaAplicacion, setFechaAplicacion] = useState(new Date().toISOString().split('T')[0]);
  const [proximaDosis, setProximaDosis] = useState('');
  const [nota, setNota] = useState('');
  const [registros, setRegistros] = useState<RegistroDosis[]>([]);
  const [loading, setLoading] = useState(false);
  const [pacienteId, setPacienteId] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    async function load() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: paciente } = await supabase
        .from('pacientes')
        .select('id')
        .eq('profile_id', user.id)
        .single();

      if (!paciente) return;
      setPacienteId(paciente.id);

      const { data } = await supabase
        .from('registros_dosis')
        .select('*')
        .eq('paciente_id', paciente.id)
        .order('fecha_aplicacion', { ascending: false })
        .limit(10);

      setRegistros(data ?? []);
    }
    load();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!pacienteId) return;
    setLoading(true);

    await supabase.from('registros_dosis').insert({
      paciente_id: pacienteId,
      medicamento,
      dosis_mg: parseFloat(dosisMg),
      fecha_aplicacion: fechaAplicacion,
      proxima_dosis: proximaDosis || null,
      nota: nota || null,
    });

    const { data } = await supabase
      .from('registros_dosis')
      .select('*')
      .eq('paciente_id', pacienteId)
      .order('fecha_aplicacion', { ascending: false })
      .limit(10);

    setRegistros(data ?? []);
    setDosisMg('');
    setNota('');
    setProximaDosis('');
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
    setLoading(false);
  }

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold text-gray-900">Registro de dosis</h1>

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
            <label className="block text-sm font-medium text-gray-700 mb-1">Dosis (mg)</label>
            <input
              type="number"
              step="0.25"
              required
              value={dosisMg}
              onChange={(e) => setDosisMg(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="0.5"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Fecha de aplicación</label>
            <input
              type="date"
              required
              value={fechaAplicacion}
              onChange={(e) => setFechaAplicacion(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Próxima dosis (opcional)</label>
          <input
            type="date"
            value={proximaDosis}
            onChange={(e) => setProximaDosis(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Nota (opcional)</label>
          <input
            type="text"
            value={nota}
            onChange={(e) => setNota(e.target.value)}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            placeholder="Ej: sitio de inyección, tolerancia..."
          />
        </div>

        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-2 rounded text-sm">
            Dosis registrada correctamente.
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50 font-medium"
        >
          {loading ? 'Guardando...' : 'Registrar dosis'}
        </button>
      </form>

      {registros.length > 0 && (
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Historial reciente</h2>
          <div className="space-y-3">
            {registros.map((r) => (
              <div key={r.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
                <div>
                  <p className="font-medium text-gray-800">{r.medicamento}</p>
                  <p className="text-sm text-gray-500">{r.dosis_mg} mg — {new Date(r.fecha_aplicacion).toLocaleDateString('es-AR')}</p>
                </div>
                {r.proxima_dosis && (
                  <span className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded">
                    Próxima: {new Date(r.proxima_dosis).toLocaleDateString('es-AR')}
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
HEREDOC

echo "→ src/app/paciente/efectos/page.tsx"
cat > src/app/paciente/efectos/page.tsx << 'HEREDOC'
'use client';

import { createClient } from '@/lib/supabase/client';
import { useState, useEffect } from 'react';
import type { EfectoSecundario } from '@/lib/types';

const TIPOS_EFECTOS = [
  'Náuseas', 'Vómitos', 'Diarrea', 'Estreñimiento', 'Dolor abdominal',
  'Fatiga', 'Dolor de cabeza', 'Mareos', 'Reacción en sitio de inyección', 'Otro',
];

export default function EfectosPage() {
  const supabase = createClient();
  const [tipo, setTipo] = useState(TIPOS_EFECTOS[0]);
  const [severidad, setSeveridad] = useState<1 | 2 | 3 | 4 | 5>(1);
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [descripcion, setDescripcion] = useState('');
  const [efectos, setEfectos] = useState<EfectoSecundario[]>([]);
  const [loading, setLoading] = useState(false);
  const [pacienteId, setPacienteId] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    async function load() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: paciente } = await supabase
        .from('pacientes')
        .select('id')
        .eq('profile_id', user.id)
        .single();

      if (!paciente) return;
      setPacienteId(paciente.id);

      const { data } = await supabase
        .from('efectos_secundarios')
        .select('*')
        .eq('paciente_id', paciente.id)
        .order('fecha', { ascending: false })
        .limit(10);

      setEfectos(data ?? []);
    }
    load();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!pacienteId) return;
    setLoading(true);

    await supabase.from('efectos_secundarios').insert({
      paciente_id: pacienteId,
      tipo,
      severidad,
      fecha,
      descripcion: descripcion || null,
    });

    const { data } = await supabase
      .from('efectos_secundarios')
      .select('*')
      .eq('paciente_id', pacienteId)
      .order('fecha', { ascending: false })
      .limit(10);

    setEfectos(data ?? []);
    setDescripcion('');
    setSuccess(true);
    setTimeout(() => setSuccess(false), 3000);
    setLoading(false);
  }

  const severidadLabel = ['', 'Leve', 'Leve-moderado', 'Moderado', 'Moderado-severo', 'Severo'];
  const severidadColor = ['', 'bg-green-100 text-green-700', 'bg-yellow-100 text-yellow-700', 'bg-orange-100 text-orange-700', 'bg-red-100 text-red-700', 'bg-red-200 text-red-800'];

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold text-gray-900">Efectos secundarios</h1>

      <form onSubmit={handleSubmit} className="bg-white shadow rounded-lg p-6 space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Tipo de efecto</label>
            <select
              value={tipo}
              onChange={(e) => setTipo(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            >
              {TIPOS_EFECTOS.map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Fecha</label>
            <input
              type="date"
              required
              value={fecha}
              onChange={(e) => setFecha(e.target.value)}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Severidad: <span className={`px-2 py-0.5 rounded text-xs font-medium ${severidadColor[severidad]}`}>{severidadLabel[severidad]}</span>
          </label>
          <input
            type="range"
            min={1}
            max={5}
            value={severidad}
            onChange={(e) => setSeveridad(parseInt(e.target.value) as 1|2|3|4|5)}
            className="w-full"
          />
          <div className="flex justify-between text-xs text-gray-400 mt-1">
            <span>1 - Leve</span>
            <span>5 - Severo</span>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Descripción (opcional)</label>
          <textarea
            value={descripcion}
            onChange={(e) => setDescripcion(e.target.value)}
            rows={3}
            className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            placeholder="Describí cómo te sentiste..."
          />
        </div>

        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-2 rounded text-sm">
            Efecto registrado correctamente.
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-orange-500 text-white py-2 px-4 rounded-md hover:bg-orange-600 disabled:opacity-50 font-medium"
        >
          {loading ? 'Guardando...' : 'Registrar efecto'}
        </button>
      </form>

      {efectos.length > 0 && (
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Historial reciente</h2>
          <div className="space-y-3">
            {efectos.map((e) => (
              <div key={e.id} className="flex items-start justify-between py-2 border-b border-gray-100 last:border-0">
                <div>
                  <p className="font-medium text-gray-800">{e.tipo}</p>
                  <p className="text-sm text-gray-500">{new Date(e.fecha).toLocaleDateString('es-AR')}</p>
                  {e.descripcion && <p className="text-sm text-gray-600 mt-1">{e.descripcion}</p>}
                </div>
                <span className={`text-xs px-2 py-1 rounded font-medium ${severidadColor[e.severidad]}`}>
                  {severidadLabel[e.severidad]}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
HEREDOC

echo "→ src/app/medico/layout.tsx"
cat > src/app/medico/layout.tsx << 'HEREDOC'
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';
import Link from 'next/link';

export default async function MedicoLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  const { data: profile } = await supabase
    .from('profiles')
    .select('nombre, role')
    .eq('id', user.id)
    .single();

  if (profile?.role !== 'medico') redirect('/paciente');

  async function signOut() {
    'use server';
    const supabase = createClient();
    await supabase.auth.signOut();
    redirect('/login');
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b border-gray-200 px-4 py-3">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-6">
            <Link href="/medico" className="font-bold text-green-700">GLP-1 Companion</Link>
            <Link href="/medico" className="text-sm text-gray-600 hover:text-gray-900">Mis pacientes</Link>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-sm text-gray-500">{profile?.nombre}</span>
            <form action={signOut}>
              <button type="submit" className="text-sm text-red-500 hover:text-red-700">
                Salir
              </button>
            </form>
          </div>
        </div>
      </nav>
      <main className="max-w-5xl mx-auto px-4 py-8">{children}</main>
    </div>
  );
}
HEREDOC

echo "→ src/app/medico/page.tsx"
cat > src/app/medico/page.tsx << 'HEREDOC'
import { createClient } from '@/lib/supabase/server';
import Link from 'next/link';
import NuevoPacienteForm from './NuevoPacienteForm';

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
HEREDOC

echo "→ src/app/medico/NuevoPacienteForm.tsx"
cat > src/app/medico/NuevoPacienteForm.tsx << 'HEREDOC'
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
HEREDOC

echo "→ src/app/medico/paciente/[id]/page.tsx"
cat > 'src/app/medico/paciente/[id]/page.tsx' << 'HEREDOC'
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
HEREDOC

echo "→ src/app/medico/paciente/[id]/tratamiento/page.tsx"
cat > 'src/app/medico/paciente/[id]/tratamiento/page.tsx' << 'HEREDOC'
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
HEREDOC

echo "→ src/app/unirse/[token]/page.tsx"
cat > 'src/app/unirse/[token]/page.tsx' << 'HEREDOC'
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
HEREDOC

echo "→ src/app/unirse/[token]/UnirseForm.tsx"
cat > 'src/app/unirse/[token]/UnirseForm.tsx' << 'HEREDOC'
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
HEREDOC

echo "→ src/components/charts/PesoChart.tsx"
cat > src/components/charts/PesoChart.tsx << 'HEREDOC'
'use client';

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import type { RegistroPeso } from '@/lib/types';

interface Props {
  data: RegistroPeso[];
}

export default function PesoChart({ data }: Props) {
  const chartData = data.map((r) => ({
    fecha: new Date(r.fecha).toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit' }),
    peso: r.peso_kg,
  }));

  return (
    <ResponsiveContainer width="100%" height={250}>
      <LineChart data={chartData} margin={{ top: 5, right: 20, left: 0, bottom: 5 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
        <XAxis dataKey="fecha" tick={{ fontSize: 12 }} stroke="#9ca3af" />
        <YAxis
          tick={{ fontSize: 12 }}
          stroke="#9ca3af"
          domain={['dataMin - 2', 'dataMax + 2']}
        />
        <Tooltip
          formatter={(value: number) => [`${value} kg`, 'Peso']}
          labelFormatter={(label) => `Fecha: ${label}`}
        />
        <Line
          type="monotone"
          dataKey="peso"
          stroke="#16a34a"
          strokeWidth={2}
          dot={{ fill: '#16a34a', r: 4 }}
          activeDot={{ r: 6 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
HEREDOC

echo "→ supabase/migrations/001_initial_schema.sql"
cat > supabase/migrations/001_initial_schema.sql << 'HEREDOC'
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles table (extends Supabase auth.users)
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text not null,
  nombre text not null,
  role text not null check (role in ('medico', 'paciente')),
  consentimiento_firmado boolean not null default false,
  created_at timestamptz not null default now()
);

-- Auto-create profile on user signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, nombre, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'nombre', ''),
    coalesce(new.raw_user_meta_data->>'role', 'paciente')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Pacientes
create table public.pacientes (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid references public.profiles(id) on delete set null,
  medico_id uuid references public.profiles(id) on delete cascade not null,
  nombre text not null,
  email text not null,
  fecha_inicio_tratamiento date,
  created_at timestamptz not null default now()
);

-- Registros de peso
create table public.registros_peso (
  id uuid primary key default uuid_generate_v4(),
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  peso_kg numeric(5,2) not null,
  fecha date not null,
  nota text,
  created_at timestamptz not null default now()
);

-- Registros de dosis
create table public.registros_dosis (
  id uuid primary key default uuid_generate_v4(),
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  medicamento text not null,
  dosis_mg numeric(6,3) not null,
  fecha_aplicacion date not null,
  proxima_dosis date,
  nota text,
  created_at timestamptz not null default now()
);

-- Efectos secundarios
create table public.efectos_secundarios (
  id uuid primary key default uuid_generate_v4(),
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  tipo text not null,
  severidad smallint not null check (severidad between 1 and 5),
  fecha date not null,
  descripcion text,
  created_at timestamptz not null default now()
);

-- Tratamientos
create table public.tratamientos (
  id uuid primary key default uuid_generate_v4(),
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  medicamento text not null,
  dosis_inicial_mg numeric(6,3) not null,
  dosis_actual_mg numeric(6,3) not null,
  objetivo_peso_kg numeric(5,2),
  observaciones text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.pacientes enable row level security;
alter table public.registros_peso enable row level security;
alter table public.registros_dosis enable row level security;
alter table public.efectos_secundarios enable row level security;
alter table public.tratamientos enable row level security;

-- Profiles policies
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

create policy "Medicos can view patient profiles" on public.profiles for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.profile_id = profiles.id
      and pacientes.medico_id = auth.uid()
    )
  );

-- Pacientes policies
create policy "Medicos manage own patients" on public.pacientes
  using (medico_id = auth.uid());

create policy "Pacientes view own record" on public.pacientes for select
  using (profile_id = auth.uid());

-- Registros peso policies
create policy "Pacientes manage own peso" on public.registros_peso
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = registros_peso.paciente_id
      and pacientes.profile_id = auth.uid()
    )
  );

create policy "Medicos view patient peso" on public.registros_peso for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = registros_peso.paciente_id
      and pacientes.medico_id = auth.uid()
    )
  );

-- Registros dosis policies
create policy "Pacientes manage own dosis" on public.registros_dosis
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = registros_dosis.paciente_id
      and pacientes.profile_id = auth.uid()
    )
  );

create policy "Medicos view patient dosis" on public.registros_dosis for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = registros_dosis.paciente_id
      and pacientes.medico_id = auth.uid()
    )
  );

-- Efectos secundarios policies
create policy "Pacientes manage own efectos" on public.efectos_secundarios
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = efectos_secundarios.paciente_id
      and pacientes.profile_id = auth.uid()
    )
  );

create policy "Medicos view patient efectos" on public.efectos_secundarios for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = efectos_secundarios.paciente_id
      and pacientes.medico_id = auth.uid()
    )
  );

-- Tratamientos policies
create policy "Medicos manage tratamientos" on public.tratamientos
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = tratamientos.paciente_id
      and pacientes.medico_id = auth.uid()
    )
  );

create policy "Pacientes view own tratamientos" on public.tratamientos for select
  using (
    exists (
      select 1 from public.pacientes
      where pacientes.id = tratamientos.paciente_id
      and pacientes.profile_id = auth.uid()
    )
  );
HEREDOC

echo "→ supabase/migrations/002_invite_token.sql"
cat > supabase/migrations/002_invite_token.sql << 'HEREDOC'
-- Invite tokens for patient onboarding
create table public.invite_tokens (
  id uuid primary key default uuid_generate_v4(),
  token uuid not null unique default uuid_generate_v4(),
  medico_id uuid references public.profiles(id) on delete cascade not null,
  email_paciente text not null,
  paciente_id uuid references public.pacientes(id) on delete cascade not null,
  used boolean not null default false,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.invite_tokens enable row level security;

create policy "Medicos manage own invite tokens" on public.invite_tokens
  using (medico_id = auth.uid());

create policy "Anyone can read invite tokens" on public.invite_tokens for select
  using (true);
HEREDOC

echo ""
echo "✓ Scaffold completo. Archivos creados: 31"
echo ""
echo "Próximos pasos:"
echo "  1. cp .env.local.example .env.local   # y completá con tus credenciales Supabase"
echo "  2. npm install"
echo "  3. npm run dev"
echo ""
echo "Para pushear a GitHub:"
echo "  git add -A"
echo "  git commit -m 'feat: scaffold completo MVP glp1-companion'"
echo "  git push -u origin claude/kind-franklin-git72s"
