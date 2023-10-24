bring cloud;
bring util;
bring sim;
bring "./websockets.types.w" as types;

interface StartWebSocketApiResult {
  inflight close(): inflight(): void;
  inflight url(): str;
}

pub class WebSocketApi impl types.IWebsocketsApi {
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
      let res = WebSocketApi.startWebSocketApi(this.connectFn, this.disconnectFn, this.onmessageFn);
      this._url.set("service_url", res.url());
      return () => {
        res.close();
      };
    });
  }

  pub inflight send(connectionId: str, message: str) {
    WebSocketApi.sendMessage(connectionId, message);
  }

  pub inflight url(): str {
    return this._url.get("service_url").asStr();
  }

  extern "./websockets-api-local.js" static inflight startWebSocketApi(
    connectFn: inflight (str): void,
    disconnectFn: inflight (str): void,
    onmessageFn: inflight (str, str): void
  ): StartWebSocketApiResult;
  extern "./websockets-api-local.js" static inflight sendMessage(
    connectionId: str,
    message: str,
  ): inflight(): void;
}
