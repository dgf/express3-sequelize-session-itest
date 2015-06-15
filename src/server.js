require('coffee-script/register');
require('./app')(function (err, app, db) {
  db.User.create({ login: 'admin', password: 'secret' }).then(function () {
    var server = app.listen(13431, '127.0.0.1', function () {
      console.log('server ' + server.address().address + ':' + server.address().port + ' started')
    });
  });
});
