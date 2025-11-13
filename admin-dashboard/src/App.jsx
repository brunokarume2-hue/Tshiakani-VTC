import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './services/AuthContext'
import Dashboard from './pages/Dashboard'
import AgentPrincipal from './pages/AgentPrincipal'
import Rides from './pages/Rides'
import Users from './pages/Users'
import Drivers from './pages/Drivers'
import Clients from './pages/Clients'
import Finance from './pages/Finance'
import MapView from './pages/MapView'
import SOSAlerts from './pages/SOSAlerts'
import Notifications from './pages/Notifications'
import Pricing from './pages/Pricing'
import Layout from './components/Layout'

function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Dashboard />} />
        <Route path="agent-principal" element={<AgentPrincipal />} />
        <Route path="rides" element={<Rides />} />
        <Route path="users" element={<Users />} />
        <Route path="drivers" element={<Drivers />} />
        <Route path="clients" element={<Clients />} />
        <Route path="finance" element={<Finance />} />
        <Route path="map" element={<MapView />} />
        <Route path="sos" element={<SOSAlerts />} />
        <Route path="notifications" element={<Notifications />} />
        <Route path="pricing" element={<Pricing />} />
      </Route>
    </Routes>
  )
}

function App() {
  return (
    <AuthProvider>
      <Router>
        <AppRoutes />
      </Router>
    </AuthProvider>
  )
}

export default App

