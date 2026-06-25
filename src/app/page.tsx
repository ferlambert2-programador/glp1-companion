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
