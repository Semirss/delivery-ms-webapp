import AdminDashboard from './AdminDashboard';
import { isAdminRequest } from '@/lib/admin-auth';
import { redirect } from 'next/navigation';

export default async function AdminPage() {
  if (!await isAdminRequest()) redirect('/admin/login');
  return <AdminDashboard />;
}
