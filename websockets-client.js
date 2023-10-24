const WebSocket = require("ws");
module.exports.initWebsocket = (url) => {
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

