import ballerina/lang.runtime;
import ballerina/websocket;

listener websocket:Listener websocketListener = check new (9090);

@websocket:ServiceConfig {
    dispatcherKey: "type",
    idleTimeout: 5
}
service /graphql_over_websocket on websocketListener {
    resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new WsService();
    }
}

service class WsService {
    *websocket:Service;
    private boolean initiatedConnection = false;
    private final map<SubscriptionHandler> activeConnections = {};

    isolated remote function onConnectionInit(ConnectionInit message) returns ConnectionAck|TooManyInitializationRequests {
        lock {
            if self.initiatedConnection {
                return TOO_MANY_INITIALIZATION_REQUESTS;
            }
            self.initiatedConnection = true;
            return {'type: WS_ACK};
        }
    }

    isolated remote function onPingMessage(PingMessage pingMessage) returns PongMessage {
        return {'type: WS_PONG};
    }

    isolated remote function onIdleTimeout() returns ConnectionInitTimeout? {
        lock {
            if !self.initiatedConnection {
                return CONNECTION_INIT_TIMEOUT;
            }
        }
        return;
    }

    isolated remote function onSubscribe(websocket:Caller caller, Subscribe message)
    returns Next|Complete|Unauthorized|SubscriberAlreadyExists|websocket:Error? {
        // Validate the subscription request
        SubscriptionHandler handler = new (message.id);
        lock {
            if !self.initiatedConnection {
                return UNAUTHORIZED;
            }
            if self.activeConnections.hasKey(message.id) {
                return {status: 4409, reason: string `Subscriber for ${message.id} already exists`};
            }
            self.activeConnections[message.id] = handler;
        }
        // Process the subscription request
        _ = start executeQuery(caller, message.clone(), handler);
        return;
    }

    isolated remote function onComplete(Complete message) {
        lock {
            if self.activeConnections.hasKey(message.id) {
                SubscriptionHandler handler = self.activeConnections.remove(message.id);
                handler.setUnsubscribed();
            }
        }
    }

    isolated remote function onError(error errorMessage) returns InvalidMessage? {
        if errorMessage.message().endsWith("ConversionError") {
            return {status: 4400, reason: "Invalid message"};
        }
        return;
    }

}

isolated function executeQuery(websocket:Caller caller, Subscribe message, SubscriptionHandler handler)
    returns websocket:Error? {

    runtime:sleep(1); // Simulate a delay
    if message.payload.query == "" {
        return;
    }

    Next|Complete response;
    foreach int i in 0 ... 3 {
        if i != 3 {
            response = {'type: WS_NEXT, id: message.id, payload: "Next"};
        } else {
            response = {'type: WS_COMPLETE, id: message.id};
        }

        // Send the response
        if handler.getUnsubscribed() {
            return;
        }
        if response is Complete {
            _ = handler.setUnsubscribed();
        }
        check caller->writeMessage(response);
    }
}
