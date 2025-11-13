import { useEffect, useState } from 'react'
import { format } from 'date-fns'
import api from '../services/api'

export default function Notifications() {
  const [showSendModal, setShowSendModal] = useState(false)
  const [notifications, setNotifications] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadNotifications()
  }, [])

  const loadNotifications = async () => {
    try {
      // Charger les notifications récentes (pour affichage)
      const response = await api.get('/notifications/all?limit=100')
      setNotifications(response.data || [])
    } catch (error) {
      console.error('Erreur chargement notifications:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSendNotification = async (formData) => {
    try {
      await api.post('/notifications/send', formData)
      alert('Notification envoyée avec succès')
      setShowSendModal(false)
    } catch (error) {
      alert('Erreur lors de l\'envoi')
      console.error(error)
    }
  }

  if (loading) {
    return <div className="text-center py-12">Chargement...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-800">Gestion des notifications</h1>
        <button
          onClick={() => setShowSendModal(true)}
          className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-semibold"
        >
          Envoyer une notification
        </button>
      </div>

      {/* Statistiques */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-xl shadow">
          <p className="text-sm text-gray-600 mb-2">Total envoyées</p>
          <p className="text-3xl font-bold text-gray-800">{notifications.length}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow">
          <p className="text-sm text-gray-600 mb-2">Non lues</p>
          <p className="text-3xl font-bold text-orange-600">
            {notifications.filter(n => !n.isRead).length}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow">
          <p className="text-sm text-gray-600 mb-2">Promotions</p>
          <p className="text-3xl font-bold text-blue-600">
            {notifications.filter(n => n.type === 'promotion').length}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow">
          <p className="text-sm text-gray-600 mb-2">Système</p>
          <p className="text-3xl font-bold text-purple-600">
            {notifications.filter(n => n.type === 'system').length}
          </p>
        </div>
      </div>

      {/* Liste des notifications récentes */}
      <div className="bg-white rounded-xl shadow overflow-hidden">
        <div className="p-6 border-b">
          <h2 className="text-xl font-semibold">Notifications récentes</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Titre</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Message</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {notifications.slice(0, 20).map((notification) => (
                <tr key={notification.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      notification.type === 'promotion' ? 'bg-blue-100 text-blue-800' :
                      notification.type === 'security' ? 'bg-red-100 text-red-800' :
                      notification.type === 'system' ? 'bg-purple-100 text-purple-800' :
                      'bg-green-100 text-green-800'
                    }`}>
                      {notification.type}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm font-medium">{notification.title}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">{notification.message}</td>
                  <td className="px-6 py-4 text-sm text-gray-500">
                    {format(new Date(notification.createdAt), 'dd/MM/yyyy HH:mm')}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      notification.isRead
                        ? 'bg-green-100 text-green-800'
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {notification.isRead ? 'Lue' : 'Non lue'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {notifications.length === 0 && (
            <div className="text-center py-12 text-gray-500">
              Aucune notification
            </div>
          )}
        </div>
      </div>

      {/* Modal d'envoi */}
      {showSendModal && (
        <SendNotificationModal
          onClose={() => setShowSendModal(false)}
          onSend={handleSendNotification}
        />
      )}
    </div>
  )
}

function SendNotificationModal({ onClose, onSend }) {
  const [formData, setFormData] = useState({
    userId: '',
    type: 'system',
    title: '',
    message: '',
    rideId: ''
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    const data = {
      type: formData.type,
      title: formData.title,
      message: formData.message
    }
    if (formData.userId) data.userId = parseInt(formData.userId)
    if (formData.rideId) data.rideId = parseInt(formData.rideId)
    onSend(data)
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b">
          <div className="flex justify-between items-center">
            <h2 className="text-2xl font-bold text-gray-800">Envoyer une notification</h2>
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700 text-2xl"
            >
              ×
            </button>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Type de notification
            </label>
            <select
              value={formData.type}
              onChange={(e) => setFormData({ ...formData, type: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
              required
            >
              <option value="system">Système</option>
              <option value="promotion">Promotion</option>
              <option value="security">Sécurité</option>
              <option value="ride">Course</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Titre
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Message
            </label>
            <textarea
              value={formData.message}
              onChange={(e) => setFormData({ ...formData, message: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
              rows={4}
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              ID Utilisateur (optionnel - laisser vide pour envoyer à tous)
            </label>
            <input
              type="number"
              value={formData.userId}
              onChange={(e) => setFormData({ ...formData, userId: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
              placeholder="Laissez vide pour envoyer à tous"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              ID Course (optionnel)
            </label>
            <input
              type="number"
              value={formData.rideId}
              onChange={(e) => setFormData({ ...formData, rideId: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg"
              placeholder="ID de la course associée"
            />
          </div>

          <div className="flex gap-4 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
            >
              Envoyer
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

