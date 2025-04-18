import ballerina/lang.runtime;
import ballerina/websocket;

listener websocket:Listener websocketListener = check new (9090);

@websocket:ServiceConfig {
    dispatcherKey: "type",
    dispatcherStreamId: "id",
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
    returns stream<Next|Complete, error?>|Unauthorized|SubscriberAlreadyExists {
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
        return getResultStream(5);
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

isolated class ResultGenerator {
    private int i = 0;
    private int n;

    isolated function init(int n) {
        self.n = n;
    }

    public isolated function next() returns record {|Next|Complete value;|}|error? {
        lock {
            self.i += 1;
            runtime:sleep(1); // Simulate a delay

            if self.i == self.n + 1 {
                return;
            }
            if self.i == self.n {
                readonly & Complete complete = {id: self.i.toString()};
                return {value: complete};
            }
            readonly & Next next = {id: self.i.toString(), payload: "Next Payload"};
            return {value: next};
        }
    }
}

isolated function getResultStream(int n) returns stream<Next|Complete, error?> {
    ResultGenerator resultGenerator = new (n);
    stream<Next|Complete, error?> result = new (resultGenerator);
    return result;
}
