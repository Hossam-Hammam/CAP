const cds = require('@sap/cds');
class POService extends cds.ApplicationService {
    init() {
        const { PO } = this.entities

        this.on(['approve', 'reject'], PO, async req => {
            const po = await SELECT.one.from(req.subject)
            if (!po) return req.reject(404, 'Purchase order not found')

            // Level 1 decides first; level 2 only after level 1 approved.
            const level = po.L1Approve === null ? 1
                : po.L1Approve === true && po.L2Approve === null ? 2
                : 0
            if (!level) return req.reject(409, `PO ${po.PONumber} has no open approval step`)
            if (!req.user.is(`L${level}Approver`)) return req.reject(403, `PO ${po.PONumber} needs a level ${level} approver`)
            if (level === 2 && po.L1By === req.user.id) return req.reject(403, 'Level 2 must be approved by someone other than the level 1 approver')

            const approved = req.event === 'approve'
            if (!approved && !req.data.reason) return req.reject(400, 'Enter a reason for the rejection')

            await UPDATE(req.subject).with({
                [`L${level}Approve`]: approved,
                [`L${level}By`]: req.user.id,
                [`L${level}Date`]: new Date().toISOString(),
                RejectReason: approved ? null : req.data.reason
            })
        })

        this.on('userInfo', req => ({
            id: req.user.id,
            authorized: req.user.is('POViewer'),
            canApproveL1: req.user.is('L1Approver'),
            canApproveL2: req.user.is('L2Approver')
        }))

        return super.init()
    }
}
module.exports = POService