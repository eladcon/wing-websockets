bring ex;
bring util;
bring "./websockets.types.w" as types;
bring "./websockets.sim.w" as websockets_sim;
bring "./websockets.aws.w" as websockets_aws;

pub class WebSocketApi impl types.IWebSocketApi {
  api: types.IWebSocketApi;
  init() {
    let target = util.env("WING_TARGET");

    if target == "sim" {
      this.api = new websockets_sim.WebSocketApi();
    } elif target == "tf-aws" {
      this.api = new websockets_aws.WebSocketApi();
    } else {
      throw "unsupported target ${target}";
    }
  }

  pub onConnect(fn: inflight (str): void) {
    this.api.onConnect(fn);
  }

  pub onDisconnect(fn: inflight (str): void) {
    this.api.onDisconnect(fn);
  }

  pub onMessage(fn: inflight (str, str): void) {
    this.api.onMessage(fn);
  }

  pub initialize() {
    this.api.initialize();
  }

  pub inflight send(connectionId: str, message: str) {
    this.api.send(connectionId, message);
  }

  pub inflight url(): str {
    return this.api.url();
  }
}
