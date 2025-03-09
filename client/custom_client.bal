import ballerina/io;
import ballerina/lang.runtime;
import ballerina/websocket;

type SubscribeMessage record {|
    string 'type;
    string id;
    record {|
        string? operationName?;
        string query;
        map<json>? variables?;
        map<json>? extensions?;
    |} payload;
|};

map<string> scenarios = {
    "1": "Successful connection initialisation",
    "2": "Connection initialisation timeout",
    "3": "Too many initialisation requests",
    "4": "Unauthorized: Send subscribe before connection init",
    "5": "Subscriber already exists",
    "6": "Successful subscription: Server dispatches the Complete",
    "7": "Successful subscription: Client sends Complete",
    "8": "Invalid message: Send invalid message"
};

public function main() returns error? {
    io:println("Available scenarios:");
    foreach string key in scenarios.keys() {
        io:println(key + ": " + (scenarios[key] ?: ""));
    }
    string input = io:readln("Enter the scenario number: ");
    io:println();

    match input {
        "1" => {
            check testConnectionInit();
        }
        "2" => {
            check testConnectionInitTimeout();
        }
        "3" => {
            check testTooManyInitRequests();
        }
        "4" => {
            check testUnauthorized();
        }
        "5" => {
            check testSubscriberAlreadyExists();
        }
        "6" => {
            check testSuccessfulSubscription();
        }
        "7" => {
            check testClientSendsComplete();
        }
        "8" => {
            check testInvalidMessage();
        }
        _ => {
            io:println("Invalid scenario number");
        }
    }
}

function testConnectionInit() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");
    check wsClient->writeMessage({'type: "connection_init"});
    anydata response = check wsClient->readMessage();
    io:println("Response: " + response.toString());
}

function testConnectionInitTimeout() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");
    anydata response = check wsClient->readMessage();
    io:println("Response: " + response.toString());
}

function testTooManyInitRequests() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");
    check wsClient->writeMessage({'type: "connection_init"});
    anydata response1 = check wsClient->readMessage();
    io:println("Response 1: " + response1.toString());

    check wsClient->writeMessage({'type: "connection_init"});
    anydata|websocket:Error response2 = wsClient->readMessage();
    if response2 is websocket:Error {
        io:println("Response 2: " + response2.toString());
    }
    runtime:sleep(1);
    io:println("Is connection open: " + wsClient.isOpen().toString());
}

function testUnauthorized() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");
    SubscribeMessage subscribeMessage = {
        'type: "subscribe",
        id: "1",
        payload: {
            query: "subscription { mySubscription { id } }"
        }
    };
    check wsClient->writeMessage(subscribeMessage);
    anydata|websocket:Error response = wsClient->readMessage();
    if response is websocket:Error {
        io:println("Response: " + response.toString());
    }
    runtime:sleep(1);
    io:println("Is connection open: " + wsClient.isOpen().toString());
}

function testSubscriberAlreadyExists() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");
    check wsClient->writeMessage({'type: "connection_init"});
    anydata initRes = check wsClient->readMessage();
    io:println("Init response: " + initRes.toString());

    SubscribeMessage subscribeMessage = {
        'type: "subscribe",
        id: "1",
        payload: {
            query: ""
        }
    };
    check wsClient->writeMessage(subscribeMessage);
    check wsClient->writeMessage(subscribeMessage);
    anydata|websocket:Error response = wsClient->readMessage();
    io:print("Response: ");
    io:println(response);

    runtime:sleep(1);
    io:println("Is connection open: " + wsClient.isOpen().toString());
}

function testSuccessfulSubscription() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");
    check wsClient->writeMessage({'type: "connection_init"});
    anydata _ = check wsClient->readMessage();

    SubscribeMessage subscribeMessage = {
        'type: "subscribe",
        id: "1",
        payload: {
            query: "subscription { mySubscription { id } }"
        }
    };
    check wsClient->writeMessage(subscribeMessage);

    while true {
        json response = check wsClient->readMessage();
        io:println("Response: " + response.toString());
        if response.'type == "complete" {
            break;
        }
    }
}

function testClientSendsComplete() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");
    check wsClient->writeMessage({'type: "connection_init"});
    anydata _ = check wsClient->readMessage();

    SubscribeMessage subscribeMessage = {
        'type: "subscribe",
        id: "1",
        payload: {
            query: "subscription { mySubscription { id } }"
        }
    };
    check wsClient->writeMessage(subscribeMessage);
    check wsClient->writeMessage({'type: "complete", id: "1"});

    // runtime:sleep(2);
    // json response = check wsClient->readMessage();
    // io:println("Response: " + response.toString());
}

function testInvalidMessage() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");
    check wsClient->writeMessage({'type: "connection_init"});
    anydata _ = check wsClient->readMessage();
    runtime:sleep(20);
}
