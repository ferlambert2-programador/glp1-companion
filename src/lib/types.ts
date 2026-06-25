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
