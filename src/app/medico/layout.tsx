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
