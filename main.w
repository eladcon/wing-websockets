bring ex;
bring util;
bring "./websockets.w" as websockets;
bring "./ws.w" as ws;

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

new std.Test(inflight () => {
  let client1 = ws.startClient(wss.url());
  let client2 = ws.startClient(wss.url());
  
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
