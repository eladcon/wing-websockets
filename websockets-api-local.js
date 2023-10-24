import { WebSocketServer } from 'ws';

export const startWebSocketApi = (
  onConnect, 
  onDisconnect, 
  onMessage) => {

  const port = Math.floor(Math.random() * 1000 + 3000);
  const wss = new WebSocketServer({ port });
  global.wss = wss;

  wss.on('connection', function connection(ws) {
    ws.id = Math.random().toString();
    ws.on('error', console.error);
    
    ws.on('message', function message(data) {
      onMessage(ws.id, data.toString("utf8"));
    });

    ws.on('close', function () {
      onDisconnect(ws.id);
    });

    onConnect(ws.id);
  });
  
  return {
    close: () => {
      console.log("closing server...");
      wss.close();
    },
    url: () => `ws://127.0.0.1:${port}`
  }
};

export const sendMessage = (connectionId, message) => {
  let wss = global.wss;
  if (!wss) {
    return;
  }

  wss.clients.forEach((ws) => {
    if (ws.id !== connectionId) {
      return;
    }

    ws.send(message)
  });
}
