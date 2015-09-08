var express = require('express');
var fs = require('fs');
var path = require('path');

var router = express.Router();

var vehiclesFilePath = path.join(__dirname, 'vehicles.json');
var peopleFilePath = path.join(__dirname, 'people.json');
var manufacturersFilePath = path.join(__dirname, 'manufacturers.json');

router.get('/vehicles', function(req, res) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    var readable = fs.createReadStream(vehiclesFilePath);
    readable.pipe(res);
});

router.get('/people', function(req, res) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    var readable = fs.createReadStream(peopleFilePath);
    readable.pipe(res);
});

router.get('/manufacturers', function(req, res) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    var readable = fs.createReadStream(manufacturersFilePath);
    readable.pipe(res);
});

module.exports = router;