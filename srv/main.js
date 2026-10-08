const cds = require('@sap/cds');
class BooksService extends cds.ApplicationService {
    init() {
        const { PO } = this.entities

        // Approvals may come in as the SAP-style flag 'X'; store them as 'TRUE' like the seed data.
        this.before(['CREATE', 'UPDATE'], PO, req => {
            for (const po of [req.data].flat()) {
                for (const field of ['L1Approve', 'L2Approve']) {
                    if (String(po[field]).trim().toUpperCase() === 'X') po[field] = 'TRUE'
                }
            }
        })

        this.on('userInfo', req => ({ id: req.user.id, authorized: req.user.is('POViewer') }))

        return super.init()
    }
}
module.exports = BooksService