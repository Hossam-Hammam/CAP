const fs = require('node:fs');
const path = require('node:path');

const input = path.join(__dirname, '..', 'db', 'data', 'POData.json');
const output = path.join(__dirname, '..', 'db', 'data', 'org.hossam-POItems.csv');

const obj = JSON.parse(fs.readFileSync(input, 'utf8'));
const rows = obj.POItems ?? [];

const cols = [
  'PO',
  'Item',
  'Material',
  'MaterialDesc',
  'Plant',
  'PlantDesc',
  'Vendor',
  'VendorNo',
  'OrderDate',
  'DeliveryDate',
  'OrderQty',
  'Unit',
  'NetValue',
  'Currency'
];

const escapeCsv = (value) => {
  if (value === null || value === undefined) return '';
  return '"' + String(value).replace(/"/g, '""') + '"';
};

const lines = [cols.join(',')]
  .concat(rows.map(row => cols.map(col => escapeCsv(row[col])).join(',')));

fs.writeFileSync(output, lines.join('\n'));
console.log(`Converted ${rows.length} POItems rows to ${path.basename(output)}`);
