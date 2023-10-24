const { ApiGatewayManagementApiClient, PostToConnectionCommand, } = require("@aws-sdk/client-apigatewaymanagementapi");

module.exports.postToConnection = async (endpoint, connectionId, data) => {
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
