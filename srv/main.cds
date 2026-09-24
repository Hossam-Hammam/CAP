using org from '../db/schema';

service bookshop {
    entity Books as projection on org.hossam.Books;
    entity Authors as projection on org.hossam.Authors;
    entity Orders as projection on org.hossam.Orders;
    entity POItems as projection on org.hossam.POItems;
    entity POItems2 as projection on org.hossam.POItems;
    entity Items as projection on org.hossam.Items;
    entity PO as projection on org.hossam.PO;
    function getBookCount() returns Integer;
}