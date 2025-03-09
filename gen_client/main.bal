import ballerina/io;

public function main() returns error? {
    GraphqlOverWebsocketClient wsClient = check new ();
    ConnectionAck res = check wsClient->doConnectionInit({'type: "connection_init"}, timeout = 65);
    io:println(res);

}
