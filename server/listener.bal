import ballerina/io;
import ballerina/websocket;

listener websocket:Listener websocketListener = check new (9090);

@websocket:ServiceConfig {dispatcherKey: "type"}
service / on websocketListener {
    resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new WsService();
    }

}

service class WsService {
    *websocket:Service;
    private boolean initiatedConnection = false;
    private final map<string> activeConnections = {};

    // TODO Forbidden
    // TODO connectionInitWaitTimeout 

    remote function onConnectionInit(ConnectionInitMessage message) returns ConnectionAckMessage|TooManyInitializationRequests {
        lock {
            if self.initiatedConnection {
                return TOO_MANY_INITIALIZATION_REQUESTS;
            }
            self.initiatedConnection = true;
            return {'type: WS_ACK};
        }
    }

    // If the server receives a actual ping frame or message that's type is ping This function will be called
    // But if it is a normal message the pong frame will not be sent
    private isolated function onPing() returns PongMessage {
        return {'type: WS_PONG};
    }

    private isolated function onSubscribe(SubscribeMessage message) returns SubscriberAlreadyExists|Unauthorized? {
        // Validate the subscription request
        lock {
            if !self.initiatedConnection {
                return UNAUTHORIZED;
            }
            if self.activeConnections.hasKey(message.id) {
                return {status: 4409, reason: string `Subscriber for ${message.id} already exists`};
            }
            self.activeConnections[message.id] = message.id;
        }
        io:println("Subscribed by ", message.id);
        return;
    }

}
