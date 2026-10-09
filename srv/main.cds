using org from '../db/schema';

service POService {

@restrict: [{ grant: 'READ', to: 'POViewer' }]
    entity Items as projection on org.hossam.Items;

@restrict: [
    { grant: 'READ', to: 'POViewer' },
    { grant: ['approve', 'reject'], to: ['L1Approver', 'L2Approver'] }
]
    entity PO as projection on org.hossam.PO { *, Vendor.Name as VendorName } actions {
    action approve();
    action reject(reason : String);
    };

    annotate POService.PO with {
    L1Approve @readonly; L1By @readonly; L1Date @readonly;
    L2Approve @readonly; L2By @readonly; L2Date @readonly;
    RejectReason @readonly;modifiedAt @odata.etag;

}

    @readonly @requires: 'POViewer'
    entity Vendors   as projection on org.hossam.Vendors;
    @readonly @requires: 'POViewer'
    entity Materials as projection on org.hossam.Materials;
    @readonly @requires: 'POViewer'
    entity Plants    as projection on org.hossam.Plants;
    
    // Lets the UI5 app ask at startup who is signed in and whether they may use it.
type UserInfo {
    id           : String;
    authorized   : Boolean;
    canApproveL1 : Boolean;
    canApproveL2 : Boolean;
}
    @requires: 'authenticated-user'
    function userInfo() returns UserInfo;
}
