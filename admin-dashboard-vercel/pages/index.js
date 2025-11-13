import { useState, useEffect } from 'react'
import Head from 'next/head'
import axios from 'axios'

export default function Dashboard() {
  const [drivers, setDrivers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [stats, setStats] = useState({
    total: 0,
    online: 0,
    offline: 0
  })

  const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.API_BASE_URL || 'https://votre-api.onrender.com/api'

  useEffect(() => {
    fetchDrivers()
  }, [])

  const fetchDrivers = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const response = await axios.get(`${apiBaseUrl}/chauffeurs`, {
        params: {
          limit: 100
        }
      })

      if (response.data.success) {
        setDrivers(response.data.drivers || [])
        
        // Calculer les statistiques
        const total = response.data.drivers?.length || 0
        const online = response.data.drivers?.filter(d => d.isOnline).length || 0
        const offline = total - online
        
        setStats({ total, online, offline })
      } else {
        setError('Erreur lors de la récupération des données')
      }
    } catch (err) {
      console.error('Erreur:', err)
      setError(err.response?.data?.error || err.message || 'Erreur de connexion à l\'API')
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      <Head>
        <title>Dashboard Tshiakani VTC - Chauffeurs</title>
        <meta name="description" content="Tableau de bord administrateur pour gérer les chauffeurs" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <div style={{ minHeight: '100vh', backgroundColor: '#f5f5f5' }}>
        {/* Header */}
        <header style={{
          backgroundColor: '#fff',
          padding: '1.5rem 2rem',
          boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
          marginBottom: '2rem'
        }}>
          <h1 style={{ margin: 0, fontSize: '1.5rem', fontWeight: 'bold', color: '#333' }}>
            🚗 Dashboard Tshiakani VTC
          </h1>
          <p style={{ margin: '0.5rem 0 0 0', color: '#666', fontSize: '0.9rem' }}>
            Gestion des chauffeurs et courses
          </p>
        </header>

        <main style={{ maxWidth: '1200px', margin: '0 auto', padding: '0 2rem 2rem' }}>
          {/* Statistiques */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '1rem',
            marginBottom: '2rem'
          }}>
            <StatCard
              title="Total Chauffeurs"
              value={stats.total}
              color="#3b82f6"
              icon="👥"
            />
            <StatCard
              title="En ligne"
              value={stats.online}
              color="#10b981"
              icon="🟢"
            />
            <StatCard
              title="Hors ligne"
              value={stats.offline}
              color="#ef4444"
              icon="🔴"
            />
          </div>

          {/* Actions */}
          <div style={{ marginBottom: '1rem', display: 'flex', gap: '1rem', alignItems: 'center' }}>
            <button
              onClick={fetchDrivers}
              disabled={loading}
              style={{
                padding: '0.5rem 1rem',
                backgroundColor: '#3b82f6',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: loading ? 'not-allowed' : 'pointer',
                opacity: loading ? 0.6 : 1,
                fontWeight: '500'
              }}
            >
              {loading ? 'Chargement...' : '🔄 Actualiser'}
            </button>
            
            {error && (
              <div style={{
                padding: '0.5rem 1rem',
                backgroundColor: '#fee2e2',
                color: '#dc2626',
                borderRadius: '6px',
                fontSize: '0.9rem'
              }}>
                ⚠️ {error}
              </div>
            )}
          </div>

          {/* Tableau des chauffeurs */}
          {loading ? (
            <div style={{
              textAlign: 'center',
              padding: '3rem',
              backgroundColor: '#fff',
              borderRadius: '8px',
              boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
            }}>
              <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>⏳</div>
              <p style={{ color: '#666' }}>Chargement des chauffeurs...</p>
            </div>
          ) : drivers.length === 0 ? (
            <div style={{
              textAlign: 'center',
              padding: '3rem',
              backgroundColor: '#fff',
              borderRadius: '8px',
              boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
            }}>
              <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>📭</div>
              <p style={{ color: '#666' }}>Aucun chauffeur trouvé</p>
            </div>
          ) : (
            <div style={{
              backgroundColor: '#fff',
              borderRadius: '8px',
              boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
              overflow: 'hidden'
            }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ backgroundColor: '#f9fafb', borderBottom: '2px solid #e5e7eb' }}>
                    <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: '#374151' }}>ID</th>
                    <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Nom</th>
                    <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Téléphone</th>
                    <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Statut</th>
                    <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Note</th>
                    <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Véhicule</th>
                    <th style={{ padding: '1rem', textAlign: 'left', fontWeight: '600', color: '#374151' }}>Distance</th>
                  </tr>
                </thead>
                <tbody>
                  {drivers.map((driver, index) => (
                    <tr
                      key={driver.id}
                      style={{
                        borderBottom: index < drivers.length - 1 ? '1px solid #e5e7eb' : 'none',
                        transition: 'background-color 0.2s'
                      }}
                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f9fafb'}
                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                    >
                      <td style={{ padding: '1rem', color: '#6b7280' }}>#{driver.id}</td>
                      <td style={{ padding: '1rem', fontWeight: '500', color: '#111827' }}>{driver.name}</td>
                      <td style={{ padding: '1rem', color: '#6b7280' }}>{driver.phoneNumber}</td>
                      <td style={{ padding: '1rem' }}>
                        <span style={{
                          display: 'inline-block',
                          padding: '0.25rem 0.75rem',
                          borderRadius: '12px',
                          fontSize: '0.875rem',
                          fontWeight: '500',
                          backgroundColor: driver.isOnline ? '#d1fae5' : '#fee2e2',
                          color: driver.isOnline ? '#065f46' : '#991b1b'
                        }}>
                          {driver.isOnline ? '🟢 En ligne' : '🔴 Hors ligne'}
                        </span>
                      </td>
                      <td style={{ padding: '1rem', color: '#6b7280' }}>
                        {driver.rating > 0 ? (
                          <span style={{ fontWeight: '500', color: '#f59e0b' }}>
                            ⭐ {driver.rating.toFixed(1)}
                          </span>
                        ) : (
                          <span style={{ color: '#9ca3af' }}>—</span>
                        )}
                      </td>
                      <td style={{ padding: '1rem', color: '#6b7280' }}>
                        {driver.vehicle || '—'}
                      </td>
                      <td style={{ padding: '1rem', color: '#6b7280' }}>
                        {driver.distanceKm ? `${driver.distanceKm.toFixed(2)} km` : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </main>
      </div>
    </>
  )
}

function StatCard({ title, value, color, icon }) {
  return (
    <div style={{
      backgroundColor: '#fff',
      padding: '1.5rem',
      borderRadius: '8px',
      boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
      borderLeft: `4px solid ${color}`
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
        <span style={{ fontSize: '1.5rem' }}>{icon}</span>
        <h3 style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280', fontWeight: '500' }}>
          {title}
        </h3>
      </div>
      <p style={{ margin: 0, fontSize: '2rem', fontWeight: 'bold', color: color }}>
        {value}
      </p>
    </div>
  )
}

