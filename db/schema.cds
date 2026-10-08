namespace org.hossam;
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

