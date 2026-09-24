// const cds = require('@sap/cds');

const { get } = require("@sap/cds");
const { SELECT, UPDATE } = require("@sap/cds/lib/ql/cds-ql");
// const Books = cds.entities('org.hossam')['Books'];
// const Authors = cds.entities('org.hossam')['Authors'];
// module.exports = cds.service.impl(async function () {
//     this.on('READ', 'Books', async (_, next) => next() );
// });
// const logger = cds.log('bookshop')
class BooksService extends cds.ApplicationService {
    init() {
        const { Books, Authors } = this.entities
        this.after('READ', Authors, (data, req) => {
            data.map(author => author.name)
            //data.forEach((x,i) => {
              //  data[i].name = x + 'XXx';
           // });
        })
        const getBookCount = async (req) => {
            let data = await SELECT.from('Books').where({ Stock: { '>=': 10 } }).columns('sum(Stock) as total' , 'title');
            return data;
        }
        this.on('getBookCount', getBookCount )
        
        return super.init()
    }
}
module.exports = BooksService