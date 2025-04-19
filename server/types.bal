import ballerina/websocket;

type ConnectionInit record {|
    string 'type = WS_INIT;
    map<json> payload?;
|};

type ConnectionAck record {|
    string 'type = WS_ACK;
    map<json> payload?;
|};

type Ping record {|
    string 'type = WS_PING;
    map<json> payload?;
|};

type Pong record {|
    string 'type = WS_PONG;
    map<json> payload?;
|};

type Subscribe record {|
    string 'type = WS_SUBSCRIBE;
    string id;
    record {|
        string? operationName?;
        string query;
        map<json>? variables?;
        map<json>? extensions?;
    |} payload;
|};

type Next record {|
    string 'type = WS_NEXT;
    string id;
    json payload;
|};

type ErrorMessage record {|
    string 'type = WS_ERROR;
    string id;
    json payload;
|};

type Complete record {|
    string 'type = WS_COMPLETE;
    string id;
|};

type TooManyInitializationRequests record {|
    *websocket:CustomCloseFrame;
    4429 status = 4429;
    string reason = "Too many initialisation requests";
|};

type Unauthorized record {|
    *websocket:CustomCloseFrame;
    4401 status = 4401;
    string reason = "Unauthorized";
|};

type ConnectionInitTimeout record {|
    *websocket:CustomCloseFrame;
    4408 status = 4408;
    string reason = "Connection initialisation timeout";
|};

type SubscriberAlreadyExists record {|
    *websocket:CustomCloseFrame;
    4409 status = 4409;
|};

type InvalidMessage record {|
    *websocket:CustomCloseFrame;
    4400 status = 4400;
|};

public final readonly & TooManyInitializationRequests TOO_MANY_INITIALIZATION_REQUESTS = {};
public final readonly & Unauthorized UNAUTHORIZED = {};
public final readonly & ConnectionInitTimeout CONNECTION_INIT_TIMEOUT = {};
