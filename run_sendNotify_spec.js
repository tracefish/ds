notify = require('./sendNotify');
fs = require('fs');
var data = fs.readFileSync('../dt.confspec');
var name = fs.readFileSync('../dt.confname');

notify.sendNotify(name, data.toString());
