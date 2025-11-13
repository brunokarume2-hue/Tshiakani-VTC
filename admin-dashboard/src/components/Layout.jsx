import { Outlet, Link, useLocation } from 'react-router-dom'
import { useAuth } from '../services/AuthContext'

export default function Layout() {
  const { user } = useAuth()
  const location = useLocation()

  const menuItems = [
    { path: '/', label: 'Tableau de bord', icon: '📊' },
    { path: '/agent-principal', label: 'Agent Principal', icon: '🤖' },
    { path: '/rides', label: 'Courses', icon: '🚗' },
    { path: '/users', label: 'Utilisateurs', icon: '👥' },
    { path: '/drivers', label: 'Conducteurs', icon: '🏍️' },
    { path: '/clients', label: 'Clients', icon: '👤' },
    { path: '/finance', label: 'Finance', icon: '💰' },
    { path: '/pricing', label: 'Tarification', icon: '💵' },
    { path: '/map', label: 'Carte', icon: '🗺️' },
    { path: '/sos', label: 'Alertes SOS', icon: '🚨' },
    { path: '/notifications', label: 'Notifications', icon: '🔔' }
  ]

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="fixed left-0 top-0 h-full w-64 bg-white shadow-lg">
        <div className="p-6">
          <h1 className="text-2xl font-bold text-green-600">Tshiakani VTC</h1>
          <p className="text-sm text-gray-500 mt-1">Dashboard Admin</p>
        </div>

        <nav className="mt-8">
          {menuItems.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`flex items-center gap-3 px-6 py-3 ${
                location.pathname === item.path
                  ? 'bg-green-50 text-green-600 border-r-4 border-green-600'
                  : 'text-gray-700 hover:bg-gray-50'
              }`}
            >
              <span className="text-xl">{item.icon}</span>
              <span className="font-medium">{item.label}</span>
            </Link>
          ))}
        </nav>

        <div className="absolute bottom-0 w-full p-6 border-t">
          <div className="mb-4">
            <p className="font-semibold text-gray-800">{user?.name || 'Admin'}</p>
            <p className="text-sm text-gray-500">{user?.phoneNumber || ''}</p>
            <p className="text-xs text-gray-400 mt-1">Mode accès libre</p>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="ml-64 p-8">
        <Outlet />
      </main>
    </div>
  )
}

