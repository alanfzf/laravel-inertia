import { createInertiaApp } from "@inertiajs/react"
import Layout from "#resources/layouts/layout.jsx"

createInertiaApp({
    layout: () => Layout,
    withApp(app) {
        // here we can inject some context
        return app
    },
})
