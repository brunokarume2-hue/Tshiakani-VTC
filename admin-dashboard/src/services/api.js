import axios from 'axios'

// Utiliser le proxy Vite en développement, ou l'URL directe en production
const API_URL = import.meta.env.VITE_API_URL || (import.meta.env.DEV ? '/api' : 'http://localhost:3000/api')
console.log('🔧 Configuration API:', { 
  API_URL, 
  env: import.meta.env.VITE_API_URL,
  mode: import.meta.env.MODE,
  dev: import.meta.env.DEV
})

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  },
  timeout: 10000 // 10 secondes de timeout
})

// Intercepteur pour ajouter le token et la clé API admin
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  
  // Ajouter la clé API admin pour les routes /api/admin/*
  if (config.url?.includes('/admin/')) {
    const adminApiKey = import.meta.env.VITE_ADMIN_API_KEY || 'aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8'
    if (adminApiKey) {
      config.headers['X-ADMIN-API-KEY'] = adminApiKey
    }
  }
  
  return config
})

// Intercepteur pour gérer les erreurs
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('admin_token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api

