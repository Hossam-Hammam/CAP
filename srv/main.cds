using org from '../db/schema';

service bookshop {
    // PO data is only served to users holding the POViewer role:
    // 401 if not signed in, 403 if signed in without the role.
    @requires: 'POViewer'
    entity Items as projection on org.hossam.Items;
    @requires: 'POViewer'
    entity PO as projection on org.hossam.PO;


    // Lets the UI5 app ask at startup who is signed in and whether they may use it.
    type UserInfo {
        id         : String;
        authorized : Boolean;
    }
    @requires: 'authenticated-user'
    function userInfo() returns UserInfo;
}
