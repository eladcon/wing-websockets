pub interface IWebSocketApi {
  onConnect(fn: inflight (str): void);
  onDisconnect(fn: inflight (str): void);
  onMessage(fn: inflight (str, str): void);
  inflight send(connectionId: str, message: str): void;
  inflight url(): str;
  initialize(): void;
}
