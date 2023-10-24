bring ex;
bring util;
bring "./websockets.w" as websockets;

let connections = new ex.Table(name: "connections", primaryKey: "connectionId", columns: {
  connectionId: ex.ColumnType.STRING
});
let wss = new websockets.WebSocketApi();
wss.onConnect(inflight (connectionId: str) => {
  connections.insert(connectionId, {connectionId: connectionId});
});

wss.onDisconnect(inflight (connectionId: str) => {
  connections.delete(connectionId);
});
wss.onMessage(inflight (connectionId: str, message: str) => {
  for connection in connections.list() {
    let currentConnectionId = connection.get("connectionId").asStr();
    if (currentConnectionId != connectionId) {
      wss.send(currentConnectionId, message);
    }
  }
});

wss.initialize();

interface WebsocketTestClient {
  inflight send(message: str);
  inflight messages(): Array<str>;
  inflight close();
}

class Util {
  extern "./websockets-client.js" pub static inflight initWebsocket(
    url: str,
  ): WebsocketTestClient; 
}

new std.Test(inflight () => {
  let client1 = Util.initWebsocket(wss.url());
  let client2 = Util.initWebsocket(wss.url());
  
  util.waitUntil(inflight () => {
    return connections.list().length == 2;
  }, timeout: 50s);

  client1.send("hello");
  
  util.waitUntil(inflight () => {
    return client2.messages().length > 0;
  }, timeout: 50s);
  
  assert(client2.messages().length == 1);
  assert(client2.messages().at(0) == "hello");
  
  client1.close();
  client2.close();
}, timeout: 3m) as "can send and recieve messages";
