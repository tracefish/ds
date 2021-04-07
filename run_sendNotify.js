notify = $.isNode() ? require('./sendNotify') : '';
var data = fs.readFileSync('../dt.conf');
var name = fs.readFileSync('../dt.confname');
if ($.isNode()) {
  await notify.sendNotify(name, data.toString());
}
