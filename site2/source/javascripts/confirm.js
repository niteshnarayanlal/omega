function callback_confirmed_registration(res, error){
  // XXX ugly
  alert("Done... redirecting");
  window.location = 'http://localhost/womega';
};

function confirm_registration(code){
  omega_web_request('users::confirm_register', code, callback_confirmed_registration);
};

$(document).ready(function(){ 
  var rc = $.url(window.location);
  rc = rc.param('rc');
  confirm_registration(rc);
});