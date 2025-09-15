import { defineConfig } from "vite"
import laravel from "laravel-vite-plugin"
import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import path from "path"

const serverConfig = {
    port: 5173,
    hmr: {
        host: "localhost",
    },
}

export default defineConfig({
    server: serverConfig,
    plugins: [
        tailwindcss(),
        react(),
        laravel({
            input: ["resources/js/app.jsx", "resources/css/app.css"],
            refresh: [
                {
                    paths: [
                        "app/**/*.php",
                        "resources/**/*.js",
                        "resources/**/*.jsx",
                        "resources/**/*.css",
                        "resources/views/**/*.blade.php",
                    ],
                    config: { delay: 100 },
                },
            ],
        }),
    ],
    resolve: {
        alias: {
            "@": path.resolve(__dirname, "resources/js"),
            "!": path.resolve(__dirname, "resources/images"),
            "#": path.resolve(__dirname, "resources/css"),
        },
    },
})
