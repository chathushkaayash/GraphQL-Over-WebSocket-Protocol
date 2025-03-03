import ballerina/io;
import ballerina/websocket;

public function main() returns error? {
    websocket:Client wsClient = check new ("ws://localhost:9090/");

    check wsClient->writeMessage({ 'type: "connection_init"});
    check wsClient->writeMessage({ 'type: "connection_init"});
    io:println("Message sent to the server");

    anydata res1 = check wsClient->readMessage();
    io:println("Message received from the server: ", res1);

    anydata res2 = check wsClient->readMessage();
    io:println("Message received from the server: ", res2);

    io:println(wsClient.isOpen());
}
