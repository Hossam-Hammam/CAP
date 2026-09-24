const fs = require('node:fs/promises')
const cors = require('cors')
const cds = require('@sap/cds')

// Dev-only CORS: reflect the caller's origin and allow the methods/headers
// the UI5 app's OData calls (including approval PATCHes) need. Without this,
// the browser's preflight OPTIONS request for PATCH gets rejected before the
// actual request is ever sent.
cds.on('bootstrap', app => {
    app.use(cors({
        origin: true,
        methods: ['GET', 'POST', 'PUT',  'PATCH','DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization']
    }))
})

cds.on('listening', async () => {
    await fs.writeFile('listening', '')
})