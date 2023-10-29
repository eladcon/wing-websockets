bring cloud;
bring sim;
bring "./websockets.types.w" as types;
bring "./ws.w" as ws;

pub class WebSocketApi impl types.IWebSocketApi {
  var connectFn: inflight (str): void;
  var disconnectFn: inflight (str): void;
  var onmessageFn: inflight (str, str): void;
  _url: sim.State;

  init() {
    this.connectFn = inflight () => {};
    this.disconnectFn = inflight () => {};
    this.onmessageFn = inflight () => {};
    this._url = new sim.State();
  }

  pub onConnect(fn: inflight (str): void) {
    this.connectFn = fn;
  }

  pub onDisconnect(fn: inflight (str): void) {
    this.disconnectFn = fn;
  }

  pub onMessage(fn: inflight (str, str): void) {
    this.onmessageFn = fn;
  }

  // TODO: https://github.com/winglang/wing/issues/4324
  pub initialize() {
    new cloud.Service(inflight () => {
      let res = ws.startServer(this.connectFn, this.disconnectFn, this.onmessageFn);
      this._url.set("service_url", res.url());
      return () => {
        res.close();
      };
    });
  }

  pub inflight send(connectionId: str, message: str) {
    ws.sendMessage(connectionId, message);
  }

  pub inflight url(): str {
    return this._url.get("service_url").asStr();
  }
}
