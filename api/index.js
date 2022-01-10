const express = require("express");
const {Pool, Client} = require('pg');

const pool = new Pool({
    user: process.env.POSTGRES_USER,
    host: process.env.POSTGRES_HOST,
    database: process.env.POSTGRES_DB,
    password: process.env.POSTGRES_PASSWORD,
    port: process.env.POSTGRES_PORT
});

var app = express();app.listen(process.env.PORT, () => {
     console.log("Server running on port " + process.env.PORT);
});


app.get('/api', (req, res) => {
    res.send('Hello World!')
})

app.use('/api/static', express.static('static'));

app.get('/api/outage/:time', function (req, res) {
	//https://gis.stackexchange.com/a/191446/83950
	let sql = `SELECT jsonb_build_object(
               	 'type',     'FeatureCollection',
               	 'features', jsonb_agg(features.feature)
               )
               FROM (
                 SELECT jsonb_build_object(
               	   'type',       'Feature',
               	   'id',         ogc_fid,
               	   'geometry',   ST_AsGeoJSON(geometry)::jsonb,
               	   'properties', to_jsonb(inputs) - 'ogc_fid' - 'geometry'
                 ) AS feature
                 FROM (SELECT * FROM test_table WHERE timestamp = to_timestamp($1)) inputs) features;
               `;

	pool.query(sql, [req.params.time], (err,data)=>{
		res.send(data.rows[0].jsonb_build_object);
	});
});
