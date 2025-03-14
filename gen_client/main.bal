import ballerina/io;

public function main() returns error? {
    GraphqlOverWebsocketClient wsClient = check new ();
    ConnectionAck res = check wsClient->doConnectionInit({'type: "connection_init"}, timeout = 10);
    io:println(res);
    PongMessage res2 = check wsClient->doPingMessage({'type: "ping"},timeout = 10);
    io:println(res2);

}
