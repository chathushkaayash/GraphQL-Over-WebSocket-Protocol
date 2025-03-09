import ballerina/io;

public function main() returns error? {
    Client wsClient = check new ();
    ConnectionAckMessage res = check wsClient->doConnectionInit({'type: "connection_init"}, timeout = 65);
    io:println(res);

}
