namespace org.hossam;

using {
  cuid,
  Country
} from '@sap/cds-common-content';

entity Books : cuid {
  title  : String;
  author : Association to Authors
             on author.ID = XID;
  XID    : type of Authors : ID;
  Stock  : Integer;
}

entity Authors : cuid {
  name    : String;
  Country : Country;
  Books   : Association to many Books
              on Books.XID = ID;
}


entity Orders : cuid {
  Items   : Composition of many {
              key pos      : Integer;
                  quantity : Integer;
            };
  comment : String;
}

entity POItems {
  key PO           : String;
  key Item         : String;
      Material     : String;
      MaterialDesc : String;
      Plant        : String;
      PlantDesc    : String;
      Vendor       : String;
      VendorNo     : String;
      OrderDate    : String;
      DeliveryDate  : String;
      OrderQty     : Integer;
      Unit         : String;
      NetValue     : Decimal(15,2);
      Currency     : String;
}
entity Items {
    key PONumber : String;
    key Item         : String;
      Material     : String;
      MaterialDesc : String;
      Plant        : String;
      PlantDesc    : String;
      OrderDate    : String;
      DeliveryDate  : String;
      OrderQty     : Integer;
      Unit         : String;
      NetValue     : Decimal(15,2);
      Currency     : String;
      PO : Association to PO on PO.PONumber = PONumber;

}

entity PO {
  key PONumber           : String;
  Items                  : Composition of many Items on Items.PONumber = PONumber;
  Vendor       : String;
  VendorNo     : String;
  L1Approve    : String;
  L2Approve    : String;
}

// entity Orders : cuid {
//   Items : Composition of many OrderItems on Items.parent = $self;
//   comment : String;
// }


/* entity OrderItems { // to be accessed through Orders only
  key parent : Association to Orders;
  key pos    : Integer;
  quantity   : Integer;
} */
