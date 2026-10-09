namespace org.hossam;
using { Currency, managed } from '@sap/cds-common-content';

entity PO : managed {
  key PONumber           : String;
  Items                  : Composition of many Items on Items.PO = $self;
  Vendor       : Association to Vendors @mandatory @assert.target;
  L1Approve    : Boolean;
  L2Approve    : Boolean;
  L1By         : String;
  L1Date       : Timestamp;
  L2By         : String;
  L2Date       : Timestamp;
  RejectReason : String(255);
}

entity Items {
    key PO : Association to PO;
    key Item         : String;
      Material     : Association to Materials @assert.target;
      Plant        : Association to Plants @assert.target;
      OrderDate    : Date;
      DeliveryDate : Date;
      OrderQty     : Integer @assert.range: [1, 999999999];
      Unit         : String;
      NetValue     : Decimal(15,2);
      Currency     : Currency;
}
entity Vendors {
  key ID   : String(10);
      Name : String(80);
}

entity Materials {
  key ID          : String(18);
      Description : String(40);
}

entity Plants {
  key ID          : String(4);
      Description : String(30);
}


