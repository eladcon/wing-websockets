import WebSocket, { WebSocketServer } from 'ws';
import { ApiGatewayManagementApiClient, PostToConnectionCommand, } from "@aws-sdk/client-apigatewaymanagementapi";

export const startServer = (
  onConnect, 
  onDisconnect, 
  onMessage) => {

  const port = Math.floor(Math.random() * 1000 + 3000);
  const wss = new WebSocketServer({ port });
  global.wss = wss;

  wss.on('connection', (ws) => {
    ws.id = Math.random().toString().slice(-6);
    ws.on('error', console.error);
    
    ws.on('message', (data) => {
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

export const startClient = (url) => {
  const ws = new WebSocket(url);
  const messages = [];
  ws.onerror = function () {
    console.log('WebSocket error');
  };
  ws.onopen = function () {
    console.log('WebSocket connection established');
  };
  ws.onclose = function () {
    console.log('WebSocket connection closed');
  };
  ws.onmessage = async function(data) {
    const msg = data.data;
    messages.push(msg);
    console.log('Message recieved: ' + msg, data.data);
  }

  return {
    send(data) {
      ws.send(data);
    },
    messages() {
      return messages;
    },
    close() {
      ws.close();
    }
  }
}

export const postToConnection = async (endpoint, connectionId, data) => {
  const apiGatewayManagementApi = new ApiGatewayManagementApiClient({
    apiVersion: "2018-11-29",
    endpoint
  });
  
  await apiGatewayManagementApi.send(
    new PostToConnectionCommand({
      Data: data,
      ConnectionId: connectionId,
    })
  );
};
