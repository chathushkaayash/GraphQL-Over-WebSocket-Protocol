isolated class SubscriptionHandler {
    private final string id;
    private boolean isUnsubscribed;

    isolated function init(string id) {
        self.id = id;
        self.isUnsubscribed = false;
    }

    isolated function getId() returns string {
        return self.id;
    }

    isolated function setUnsubscribed() {
        lock {
            self.isUnsubscribed = true;
        }
    }

    isolated function getUnsubscribed() returns boolean {
        lock {
            return self.isUnsubscribed;
        }
    }
}
