import ballerina/lang.runtime;
import ballerina/websocket;

listener websocket:Listener websocketListener = check new (9090);

@websocket:ServiceConfig {
    dispatcherKey: "type",
    idleTimeout: 5
}
service / on websocketListener {
    resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new WsService();
    }

}

service class WsService {
    *websocket:Service;
    private boolean initiatedConnection = false;
    private final map<SubscriptionHandler> activeConnections = {};

    // TODO Forbidden

    remote function onConnectionInit(ConnectionInit message) returns ConnectionAckMessage|TooManyInitializationRequests {
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

    private isolated function onIdleTimeout() returns ConnectionInitTimeout? {
        lock {
            if !self.initiatedConnection {
                return CONNECTION_INIT_TIMEOUT;
            }
        }
        return;
    }

    private isolated function onSubscribe(websocket:Caller caller, Subscribe message)
    returns Unauthorized|SubscriberAlreadyExists|websocket:Error? {
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

    private isolated function onComplete(Complete message) {
        lock {
            if self.activeConnections.hasKey(message.id) {
                SubscriptionHandler handler = self.activeConnections.remove(message.id);
                handler.setUnsubscribed();
            }
        }
    }

}

isolated function executeQuery(websocket:Caller caller, Subscribe message, SubscriptionHandler handler)
    returns websocket:Error? {

    runtime:sleep(1); // Simulate a delay
    if message.payload.query == "" {
        return;
    }

    NextMessage|Complete response;
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
