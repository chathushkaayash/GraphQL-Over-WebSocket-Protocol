import ballerina/websocket;

type ConnectionInitMessage record {|
    WS_INIT 'type;
    map<json> payload?;
|};

type ConnectionAckMessage record {|
    WS_ACK 'type;
    map<json> payload?;
|};

type PingMessage record {|
    WS_PING 'type;
    map<json> payload?;
|};

type PongMessage record {|
    WS_PONG 'type;
    map<json> payload?;
|};

type SubscribeMessage record {|
    WS_SUBSCRIBE 'type;
    string id;
    record {|
        string? operationName?;
        string query;
        map<json>? variables?;
        map<json>? extensions?;
    |} payload;
|};

type NextMessage record {|
    WS_NEXT 'type;
    string id;
    json payload;
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

type SubscriberAlreadyExists record {|
    *websocket:CustomCloseFrame;
    4409 status = 4409;
|};

public final readonly & TooManyInitializationRequests TOO_MANY_INITIALIZATION_REQUESTS = {};
public final readonly & Unauthorized UNAUTHORIZED = {};
