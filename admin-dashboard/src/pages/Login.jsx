import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../services/AuthContext'

export default function Login() {
  const [phoneNumber, setPhoneNumber] = useState('+243820098808')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [autoLogin, setAutoLogin] = useState(false)
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleAutoLogin = async () => {
    setLoading(true)
    setError('')
    const result = await login(phoneNumber, password)
    if (result.success) {
      navigate('/')
    } else {
      setError(result.error)
      setLoading(false)
    }
  }

  // Connexion automatique au chargement (optionnel)
  useEffect(() => {
    const shouldAutoLogin = localStorage.getItem('auto_login') === 'true'
    if (shouldAutoLogin && !loading) {
      handleAutoLogin()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    console.log('📝 Tentative de connexion...', { phoneNumber, password: password ? '***' : '(vide)' })
    
    const result = await login(phoneNumber, password)
    
    console.log('📊 Résultat de la connexion:', result)
    
    if (result.success) {
      console.log('✅ Connexion réussie, redirection...')
      navigate('/')
    } else {
      console.error('❌ Erreur de connexion:', result.error)
      setError(result.error || 'Erreur de connexion. Vérifiez la console pour plus de détails.')
    }
    
    setLoading(false)
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-orange-50">
      <div className="bg-white p-8 rounded-2xl shadow-xl w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-green-600 mb-2">Tshiakani VTC</h1>
          <p className="text-gray-600">Dashboard Administrateur</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Numéro de téléphone
            </label>
            <input
              type="tel"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="+243 900 000 000"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Mot de passe
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="(optionnel - laissez vide)"
            />
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
              {error}
            </div>
          )}

          <div className="flex items-center mb-4">
            <input
              type="checkbox"
              id="autoLogin"
              checked={autoLogin}
              onChange={(e) => {
                setAutoLogin(e.target.checked)
                localStorage.setItem('auto_login', e.target.checked ? 'true' : 'false')
              }}
              className="mr-2"
            />
            <label htmlFor="autoLogin" className="text-sm text-gray-600">
              Connexion automatique
            </label>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-green-600 text-white py-3 rounded-lg font-semibold hover:bg-green-700 transition disabled:opacity-50"
          >
            {loading ? 'Connexion...' : 'Se connecter'}
          </button>
        </form>
      </div>
    </div>
  )
}

