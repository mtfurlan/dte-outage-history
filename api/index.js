var express = require("express");

var app = express();app.listen(process.env.PORT, () => {
     console.log("Server running on port " + process.env.PORT);
});


app.get('/api', (req, res) => {
    res.send('Hello World!')
})

app.use('/api/static', express.static('static'));

//const {Pool, Client} = require('pg');
//
//const pool = new Pool({
//    user: process.env.POSTGRES_USER,
//    host: process.env.POSTGRES_HOST,
//    database: process.env.POSTGRES_DB,
//    password: process.env.POSTGRES_PASSWORD,
//    port: process.env.POSTGRES_PORT
//});
//
//pool.query("SELECT * FROM test_table;", (err,res)=>{
//    console.log(err,res)
//});
