<?php
if( PHP_SAPI != 'cli' ) {
  if( $_SERVER["HTTP_X_FORWARDED_PROTO"] == 'https' )
    $_SERVER["SERVER_PORT"] = 443;
  else
    $_SERVER["SERVER_PORT"] = 80;
}
function error_handler() {
  $error = error_get_last();
  if ($error) switch ($error['type']) {
    case E_ERROR: // 1
      readfile("/var/www/html/500.html");
      break;
    case E_PARSE: // 4
    case E_CORE_ERROR: // 16
    case E_CORE_WARNING: // 32
    case E_COMPILE_ERROR: // 64
    case E_COMPILE_WARNING: // 128
    case E_USER_ERROR: // 256
    case E_RECOVERABLE_ERROR: // 4096
      readfile("/var/www/html/50x.html");
      break;
    case E_WARNING: // 2
    case E_NOTICE: // 8
    case E_USER_WARNING: // 512
    case E_USER_NOTICE: // 1024
    case E_STRICT: // 2048
    case E_DEPRECATED: // 8192
    case E_USER_DEPRECATED: // 16384
  }
}
register_shutdown_function('error_handler');
?>
