/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  env: {
    API_BASE_URL: process.env.API_BASE_URL || 'https://votre-api.onrender.com/api',
  },
  // Configuration pour Vercel
  output: 'standalone',
}

module.exports = nextConfig

