var http = require('http');
var fs = require('fs');
var path = require('path');

http.createServer(function(req, res) {
    var filePath = req.url;
    if (filePath === '/favicon.ico') {
        return res.end();
    }
    res.writeHead(200, {'Content-Type': 'application/json'});
    filePath = filePath.replace(/\//g, path.sep);
    console.log('filePath: ' + filePath);
    filePath = filePath.replace(/\?.*$/, ''); // remove query string
    setTimeout(function() {
        var pathToFile = __dirname + filePath;
        console.log('reading file ' + pathToFile);
        fs.readFile(pathToFile, {
           encoding: 'utf8'
        },
        function(error, content) {
            if (error) {
                console.error(error);
                res.end();
            } else {
                res.end(content);
            }
        });
    }, 0);
}).listen(3000);
