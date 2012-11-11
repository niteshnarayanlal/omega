/* Omega User Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// global vars

// invoked when session validation is successful (eg page refresh when user is logged in)
$session_validated_callbacks = [];

// invoked when session validation is not succesful
$invalid_session_callbacks   = [];

// invoked on login
$login_callbacks             = [];

/////////////////////////////////////// public methods

/* Register function to be invoked when session is validated
 */
function on_session_validated(callback){
  $session_validated_callbacks.push(callback);
}

/* Register function to be invoked when invalid session
 * is detected.
 */
function on_invalid_session(callback){
  $invalid_session_callbacks.push(callback);
}

/* Register function to be invoked on user login
 */
function on_login(callback){
  $login_callbacks.push(callback);
}

/////////////////////////////////////// private methods

/* Create new user w/ the specified params
 */
function User(arg){
  this.id = arg.id;
  this.password = arg.password;
  this.email = arg.email;
  this.recaptcha_challenge = arg.recaptcha_challenge;
  this.recaptcha_response = arg.recaptcha_response;
  this.toJSON = function(){ return new JRObject("Users::User", this).toJSON(); };
};

/* Initialize the user session
 */
function create_session(session_id, user_id){
  // set session id on rjr nodes
  $web_node.headers['session_id'] = session_id;
  $ws_node.headers['session_id']  = session_id;
  $web_node.headers['source_node']= user_id;
  $ws_node.headers['source_node'] = user_id;

  // set session cookies
  $.cookie('omega-session', session_id);
  $.cookie('omega-user',    user_id);

  $user_id = user_id;
};

/* Destroy the user session
 */
function destroy_session(){
  // delete session cookies
  $.cookie('omega-session', null);
  $.cookie('omega-user',    null);
};

/* Callback invoked to verify user session
 */
function callback_validate_session(user, error){
  var ret = true;
  if(error){
    destroy_session();
    ret = false;
    for(var i = 0; i < $session_validated_callbacks.length; i++){
      $invalid_session_callbacks[i]();
    }
  }else{
    for(var i = 0; i < $session_validated_callbacks.length; i++){
      $session_validated_callbacks[i]();
    }
  }
  return ret;
};

/* Callback invoked on user login
 */
function callback_login_user(session, error){
  if(error){
    destroy_session();
  }else{
    create_session(session.id, session.user_id);
    for(var i = 0; i < $login_callbacks.length; i++){
      $login_callbacks[i](session, error);
    }
  }
}

/* Login the user
 */
function login_user(user){
  omega_web_request('users::login', user, callback_login_user)
};

/* Login the user
 */
function logout_user(){
  // TODO issue users::logout
  var session_id = $.cookie('omega-session');
  omega_web_request('users::logout', session_id, null);
};

/* Register the user
 */
function register_user(user, callback){
  omega_web_request('users::register', user, callback);
}

/////////////////////////////////////// initialization

$(document).ready(function(){ 

  // restore the session from cookies
  var user_id    = $.cookie('omega-user');
  var session_id = $.cookie('omega-session');
  if(user_id != null && session_id != null){
    create_session(session_id, user_id);
  }

  // validate the session
  if(user_id != null){
    // XXX hack, give socket time to open before running client
    setTimeout(function(){
      omega_web_request('users::get_entity', 'with_id', user_id, callback_validate_session);
    }, 250);
  }
});
