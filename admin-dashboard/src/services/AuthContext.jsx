import { createContext, useContext, useState, useEffect } from 'react'
import api from './api'

const AuthContext = createContext()

export function AuthProvider({ children }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Vérifier si un token existe dans localStorage
    const token = localStorage.getItem('admin_token')
    if (token) {
      // Vérifier le token avec le backend
      verifyToken(token)
    } else {
      setLoading(false)
    }
  }, [])

  const verifyToken = async (token) => {
    try {
      // Optionnel: Vérifier le token avec le backend
      // Pour l'instant, on considère que le token est valide s'il existe
      setIsAuthenticated(true)
      // Récupérer les infos utilisateur depuis le token (décodage JWT côté client)
      // Ou faire un appel API pour vérifier
    } catch (error) {
      console.error('Erreur vérification token:', error)
      localStorage.removeItem('admin_token')
      setIsAuthenticated(false)
      setUser(null)
    } finally {
      setLoading(false)
    }
  }

  const login = async (phoneNumber, password) => {
    try {
      setLoading(true)
      console.log('🔐 Tentative de connexion...', { phoneNumber })
      
      const response = await api.post('/auth/admin/login', {
        phoneNumber,
        password
      })

      if (response.data && response.data.token) {
        const { token, user } = response.data
        
        // Stocker le token
        localStorage.setItem('admin_token', token)
        
        // Mettre à jour l'état
        setIsAuthenticated(true)
        setUser(user)
        
        console.log('✅ Connexion réussie', { user })
        return { success: true, user }
      } else {
        throw new Error('Réponse invalide du serveur')
      }
    } catch (error) {
      console.error('❌ Erreur de connexion:', error)
      const errorMessage = error.response?.data?.error || error.message || 'Erreur de connexion'
      return { 
        success: false, 
        error: errorMessage 
      }
    } finally {
      setLoading(false)
    }
  }

  const logout = () => {
    localStorage.removeItem('admin_token')
    setIsAuthenticated(false)
    setUser(null)
  }

  return (
    <AuthContext.Provider value={{ isAuthenticated, user, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}

