import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig(({mode}) => {
  const env = loadEnv(mode, process.cwd());
  const basePath = env['VITE_BASE_PATH'] || '/';
  return {
    base: basePath,
    plugins: [react()],
    server: {
      proxy: {
        '/v1/': {
          target: 'http://localhost:3000/',
          changeOrigin: true,
        },
      },
    },
  }
});
