import ballerina/io;

const decimal DEFAULT_TIMEOUT = 60;

map<string> scenarios = {
    "1": "Successful connection initialisation",
    "2": "Too many initialisation requests",
    "3": "Unauthorized: Send subscribe before connection init",
    "4": "Subscriber already exists",
    "5": "Successful subscription"
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
            check testTooManyInitRequests();
        }
        "3" => {
            check testUnauthorized();
        }
        "4" => {
            check testSubscriberAlreadyExists();
        }
        "5" => {
            check testSuccessfulSubscription();
        }
        _ => {
            io:println("Invalid scenario number");
        }
    }
}

function testConnectionInit() returns error? {
    GraphqlOverWebsocketClient wsClient = check new ();
    ConnectionAck res = check wsClient->doConnectionInit({'type: "connection_init"}, timeout = DEFAULT_TIMEOUT);
    io:println("Response: " + res.toString());
}

function testTooManyInitRequests() returns error? {
    GraphqlOverWebsocketClient wsClient = check new ();
    ConnectionAck res1 = check wsClient->doConnectionInit({'type: "connection_init"}, timeout = DEFAULT_TIMEOUT);
    io:println("Response 1: " + res1.toString());

    _ = check wsClient->doConnectionInit({'type: "connection_init"}, timeout = DEFAULT_TIMEOUT);
}

function testUnauthorized() returns error? {
    GraphqlOverWebsocketClient wsClient = check new ();
    stream<Next|Complete|ErrorMessage, error?> res =
        check wsClient->doSubscribe({'type: "subscribe", id: "1", payload: {query: ""}}, timeout = DEFAULT_TIMEOUT);
    io:println("Response: ");
    printResult(res);
}

function testSubscriberAlreadyExists() returns error? {
    GraphqlOverWebsocketClient wsClient = check new ();
    _ = check wsClient->doConnectionInit({'type: "connection_init"}, timeout = DEFAULT_TIMEOUT);
    stream<Next|Complete|ErrorMessage, error?> res1 =
        check wsClient->doSubscribe({'type: "subscribe", id: "1", payload: {query: ""}}, timeout = DEFAULT_TIMEOUT);
    io:println("Response 1: ");
    printResult(res1);

    stream<Next|Complete|ErrorMessage, error?> res2 =
        check wsClient->doSubscribe({'type: "subscribe", id: "1", payload: {query: ""}}, timeout = DEFAULT_TIMEOUT);
    io:println("Response 2: ");
    printResult(res2);
}

function testSuccessfulSubscription() returns error? {
    GraphqlOverWebsocketClient wsClient = check new ();
    _ = check wsClient->doConnectionInit({'type: "connection_init"}, timeout = DEFAULT_TIMEOUT);

    Subscribe subscribe = {'type: "subscribe", id: "1", payload: {query: "subscription { mySubscription { id } }"}};
    stream<Next|Complete|ErrorMessage, error?> resultStream =
        check wsClient->doSubscribe(subscribe, timeout = DEFAULT_TIMEOUT);
    io:println("Response: ");
    printResult(resultStream);
}

function printResult(stream<Next|Complete|ErrorMessage, error?> resultStream) {
    while true {
        var result = resultStream.next();
        if result is error? {
            io:println("Error: " + (result is error ? result.message() : ""));
            break;
        }
        Next|Complete nextVal = result.value;
        if nextVal is Next {
            io:println("Next: " + nextVal.toString());
        } else {
            io:println("Complete: " + nextVal.toString());
            break;
        }
    }
}
