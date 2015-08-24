var app = require('../');

app.set('port', process.env.PORT || 3000);

var server = app.listen(app.get('port'), function() {
   console.log('Listening on port ' + server.address.port); 
});
