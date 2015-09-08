var express = require('express');
var path = require('path');
var logger = require('morgan');
var routes = require('./routes');

var app = express();

app.use(logger('dev'));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, 'assets')));


app.get('/test', function(req, res) {
    res.send('test response');
});

app.use(routes);

app.use(function(req, res, next) {
    var err = new Error('Not found');
    err.status = 404;
    next(err);
});

module.exports = app;