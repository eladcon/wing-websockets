interface StartWebSocketApiResult {
  inflight close(): inflight(): void;
  inflight url(): str;
}

interface WebsocketTestClient {
  inflight send(message: str);
  inflight messages(): Array<str>;
  inflight close();
}

pub class Util {
  extern "./ws.js" pub static inflight startServer(
    connectFn: inflight (str): void,
    disconnectFn: inflight (str): void,
    onmessageFn: inflight (str, str): void
  ): StartWebSocketApiResult;

  extern "./ws.js" pub static inflight sendMessage(
    connectionId: str,
    message: str,
  ): inflight(): void;

  extern "./ws.js" pub static inflight startClient(
    url: str,
  ): WebsocketTestClient;

  extern "./ws.js" pub static inflight postToConnection(endpoint: str, connectionId: str, data: str);
}
