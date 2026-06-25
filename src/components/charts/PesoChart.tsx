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
