# frozen_string_literal: true

module Puma
  class UnsupportedOption < RuntimeError; end

  HTTP_STATUS_CODES = {
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',
    103 => 'Early Hints',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',
    208 => 'Already Reported',
    226 => 'IM Used',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    308 => 'Permanent Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Content Too Large',
    414 => 'URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Range Not Satisfiable',
    417 => 'Expectation Failed',
    421 => 'Misdirected Request',
    422 => 'Unprocessable Content',
    423 => 'Locked',
    424 => 'Failed Dependency',
    425 => 'Too Early',
    426 => 'Upgrade Required',
    428 => 'Precondition Required',
    429 => 'Too Many Requests',
    431 => 'Request Header Fields Too Large',
    451 => 'Unavailable For Legal Reasons',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',
    507 => 'Insufficient Storage',
    508 => 'Loop Detected',
    510 => 'Not Extended (OBSOLETED)',
    511 => 'Network Authentication Required'
  }.freeze

  STATUS_WITH_NO_ENTITY_BODY = {
    204 => true,
    205 => true,
    304 => true
  }.freeze

  module Const
    PUMA_VERSION = VERSION = "6.4.0"
    CODE_NAME = "The Eagle of Durango"

    PUMA_SERVER_STRING = ["puma", PUMA_VERSION, CODE_NAME].join(" ").freeze

    FAST_TRACK_KA_TIMEOUT = 0.2

    WRITE_TIMEOUT = 10

    REQUEST_URI = "REQUEST_URI"
    REQUEST_PATH = "REQUEST_PATH"
    QUERY_STRING = "QUERY_STRING"
    CONTENT_LENGTH = "CONTENT_LENGTH"

    PATH_INFO = "PATH_INFO"

    PUMA_TMP_BASE = "puma"

    ERROR_RESPONSE = {
      400 => "HTTP/1.1 400 Bad Request\r\n\r\n",
      404 => "HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n",
      408 => "HTTP/1.1 408 Request Timeout\r\nConnection: close\r\n\r\n",
      500 => "HTTP/1.1 500 Internal Server Error\r\n\r\n",
      501 => "HTTP/1.1 501 Not Implemented\r\n\r\n",
      503 => "HTTP/1.1 503 Service Unavailable\r\n\r\n"
    }.freeze

    CHUNK_SIZE = 16 * 1024

    MAX_HEADER = 1024 * (80 + 32)

    MAX_BODY = MAX_HEADER

    REQUEST_METHOD = "REQUEST_METHOD"
    HEAD = "HEAD"

    SUPPORTED_HTTP_METHODS = %w[GET HEAD POST PUT DELETE OPTIONS TRACE PATCH].freeze

    IANA_HTTP_METHODS = %w[
      ACL
      BASELINE-CONTROL
      BIND
      CHECKIN
      CHECKOUT
      CONNECT
      COPY
      DELETE
      GET
      HEAD
      LABEL
      LINK
      LOCK
      MERGE
      MKACTIVITY
      MKCALENDAR
      MKCOL
      MKREDIRECTREF
      MKWORKSPACE
      MOVE
      OPTIONS
      ORDERPATCH
      PATCH
      POST
      PRI
      PROPFIND
      PROPPATCH
      PUT
      REBIND
      REPORT
      SEARCH
      TRACE
      UNBIND
      UNCHECKOUT
      UNLINK
      UNLOCK
      UPDATE
      UPDATEREDIRECTREF
      VERSION-CONTROL
    ].freeze

    LINE_END = "\r\n"
    REMOTE_ADDR = "REMOTE_ADDR"
    HTTP_X_FORWARDED_FOR = "HTTP_X_FORWARDED_FOR"
    HTTP_X_FORWARDED_SSL = "HTTP_X_FORWARDED_SSL"
    HTTP_X_FORWARDED_SCHEME = "HTTP_X_FORWARDED_SCHEME"
    HTTP_X_FORWARDED_PROTO = "HTTP_X_FORWARDED_PROTO"

    SERVER_NAME = "SERVER_NAME"
    SERVER_PORT = "SERVER_PORT"
    HTTP_HOST = "HTTP_HOST"
    PORT_80 = "80"
    PORT_443 = "443"
    LOCALHOST = "localhost"
    LOCALHOST_IPV4 = "127.0.0.1"
    LOCALHOST_IPV6 = "::1"
    UNSPECIFIED_IPV4 = "0.0.0.0"
    UNSPECIFIED_IPV6 = "::"

    SERVER_PROTOCOL = "SERVER_PROTOCOL"
    HTTP_11 = "HTTP/1.1"

    SERVER_SOFTWARE = "SERVER_SOFTWARE"
    GATEWAY_INTERFACE = "GATEWAY_INTERFACE"
    CGI_VER = "CGI/1.2"

    STOP_COMMAND = "?"
    HALT_COMMAND = "!"
    RESTART_COMMAND = "R"

    RACK_INPUT = "rack.input"
    RACK_URL_SCHEME = "rack.url_scheme"
    RACK_AFTER_REPLY = "rack.after_reply"
    PUMA_SOCKET = "puma.socket"
    PUMA_CONFIG = "puma.config"
    PUMA_PEERCERT = "puma.peercert"

    HTTP = "http"
    HTTPS = "https"

    HTTPS_KEY = "HTTPS"

    HTTP_VERSION = "HTTP_VERSION"
    HTTP_CONNECTION = "HTTP_CONNECTION"
    HTTP_EXPECT = "HTTP_EXPECT"
    CONTINUE = "100-continue"

    HTTP_11_100 = "HTTP/1.1 100 Continue\r\n\r\n"
    HTTP_11_200 = "HTTP/1.1 200 OK\r\n"
    HTTP_10_200 = "HTTP/1.0 200 OK\r\n"

    CLOSE = "close"
    KEEP_ALIVE = "keep-alive"

    CONTENT_LENGTH2 = "content-length"
    CONTENT_LENGTH_S = "Content-Length: "
    TRANSFER_ENCODING = "transfer-encoding"
    TRANSFER_ENCODING2 = "HTTP_TRANSFER_ENCODING"

    CONNECTION_CLOSE = "Connection: close\r\n"
    CONNECTION_KEEP_ALIVE = "Connection: Keep-Alive\r\n"

    TRANSFER_ENCODING_CHUNKED = "Transfer-Encoding: chunked\r\n"
    CLOSE_CHUNKED = "0\r\n\r\n"

    CHUNKED = "chunked"

    COLON = ": "

    NEWLINE = "\n"

    HIJACK_P = "rack.hijack?"
    HIJACK = "rack.hijack"
    HIJACK_IO = "rack.hijack_io"

    EARLY_HINTS = "rack.early_hints"

    DQUOTE = "\""
    HTTP_HEADER_DELIMITER = Regexp.escape("(),/:;<=>?@[]{}\\").freeze
    ILLEGAL_HEADER_KEY_REGEX = /[\x00-\x20#{DQUOTE}#{HTTP_HEADER_DELIMITER}]/.freeze
    ILLEGAL_HEADER_VALUE_REGEX = /[\x00-\x08\x0A-\x1F]/.freeze

    BANNED_HEADER_KEY = /\A(rack\.|status\z)/.freeze

    PROXY_PROTOCOL_V1_REGEX = /^PROXY (?:TCP4|TCP6|UNKNOWN) ([^\r]+)\r\n/.freeze
  end
end
