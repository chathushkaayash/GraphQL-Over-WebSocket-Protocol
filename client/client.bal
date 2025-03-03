import ballerina/io;
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

public function main() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");

    check wsClient->writeMessage({'type: "connection_init"});
    io:println("Message sent to the server");

    anydata res1 = check wsClient->readMessage();
    io:println("Message received from the server: ", res1);

    SubscribeMessage subscribeMessage = {
        'type: "subscribe",
        id: "1",
        payload: {
            query: "subscription { mySubscription { id } }"
        }
    };
    check wsClient->writeMessage(subscribeMessage);
    io:println("Message sent to the server");

    anydata res2 = check wsClient->readMessage();
    io:println("Message received from the server: ", res2);

    io:println(wsClient.isOpen());
}
