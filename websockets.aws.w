bring "@cdktf/provider-aws" as awsProvider;
bring "cdktf" as cdktf;
bring cloud;
bring aws;
bring "./websockets.types.w" as types;

struct WebSocketRequestContext {
  routeKey: str;
  eventType: str;
  connectionId: str;
}

struct WebSocketRequest {
  requestContext: WebSocketRequestContext;
  body: str;
}

struct WebSocketResponse {
  statusCode: num;
  body: str?;
}

pub class WebSocketApi impl types.IWebsocketsApi {
  api: awsProvider.apigatewayv2Api.Apigatewayv2Api;
  stage: awsProvider.apigatewayv2Stage.Apigatewayv2Stage;
  apiEndpoint: str;
  wsEndpoint: str;
  init() {
    this.api = new awsProvider.apigatewayv2Api.Apigatewayv2Api(
      name: "wing-websocket-tunnels", 
      protocolType: "WEBSOCKET", 
      routeSelectionExpression: "\$request.body.action"
    );

    this.stage = new awsProvider.apigatewayv2Stage.Apigatewayv2Stage(
      apiId: this.api.id,
      name: "prod",
      autoDeploy: true
    );

    this.apiEndpoint = "https://${this.api.id}.execute-api.us-east-1.amazonaws.com/${this.stage.id}";
    this.wsEndpoint = this.stage.invokeUrl;
  }

  pub onConnect(fn: inflight (str): void) {
    let handler = new cloud.Function(unsafeCast(inflight (event: WebSocketRequest): WebSocketResponse => {
      if event.requestContext.routeKey == "\$connect" {
        fn(event.requestContext.connectionId);
      }

      return {
        statusCode: 200,
        body: "ack"
      };
    })) as "connect function";

    this.createRoute(handler, "connect", "\$connect");
  }

  pub onDisconnect(fn: inflight (str): void) {
    let handler = new cloud.Function(unsafeCast(inflight (event: WebSocketRequest): WebSocketResponse => {
      if event.requestContext.routeKey == "\$disconnect" {
        fn(event.requestContext.connectionId);
      }

      return {
        statusCode: 200,
        body: "ack"
      };
    })) as "disconnect function";

    this.createRoute(handler, "disconnect", "\$disconnect");
  }

  pub onMessage(fn: inflight (str, str): void) {
    let handler = new cloud.Function(unsafeCast(inflight (event: WebSocketRequest): WebSocketResponse => {
      if event.requestContext.routeKey == "\$default" {
        fn(event.requestContext.connectionId, event.body);
      }

      return {
        statusCode: 200,
        body: "ack"
      };
    })) as "onmessage function";

    this.createRoute(handler, "default", "\$default");
  }

  pub initialize() { }

  createRoute(handler: cloud.Function, routeName: str, routeKey: str) {
    let unsafeHandler = unsafeCast(handler);
    let handlerArn: str = unsafeHandler.arn;
    let handlerInvokeArn: str = unsafeHandler.invokeArn;
    let handlerName: str = unsafeHandler.functionName;

    let policy = new awsProvider.iamPolicy.IamPolicy(
      policy: cdktf.Fn.jsonencode({
        Version: "2012-10-17",
        Statement: [
          {
            Action: [
              "lambda:InvokeFunction",
            ],
            Effect: "Allow",
            Resource: handlerArn
          },
        ]
      }),
    ) in handler;

    let role = new awsProvider.iamRole.IamRole(
      assumeRolePolicy: cdktf.Fn.jsonencode({
        Version: "2012-10-17",
        Statement: [
          {
            Action: "sts:AssumeRole",
            Effect: "Allow",
            Sid: "",
            Principal: {
              Service: "apigateway.amazonaws.com"
            }
          },
        ]
      }),
      managedPolicyArns: [policy.arn]
    ) in handler;

    let integration = new awsProvider.apigatewayv2Integration.Apigatewayv2Integration(
      apiId: this.api.id,
      integrationType: "AWS_PROXY",
      integrationUri: handlerInvokeArn,
      credentialsArn: role.arn,
      contentHandlingStrategy: "CONVERT_TO_TEXT",
      passthroughBehavior: "WHEN_NO_MATCH",
    ) in handler;

    new awsProvider.apigatewayv2IntegrationResponse.Apigatewayv2IntegrationResponse(
      apiId: this.api.id,
      integrationId: integration.id,
      integrationResponseKey: "/200/"
    ) in handler;

    let route = new awsProvider.apigatewayv2Route.Apigatewayv2Route(
      apiId: this.api.id,
      routeKey: routeKey,
      target: "integrations/${integration.id}"
    ) in handler;

    new awsProvider.apigatewayv2RouteResponse.Apigatewayv2RouteResponse(
      apiId: this.api.id,
      routeId: route.id,
      routeResponseKey: "\$default",
    ) in handler;

    new awsProvider.lambdaPermission.LambdaPermission(
      statementId: "AllowExecutionFromAPIGateway",
      action: "lambda:InvokeFunction",
      functionName: handlerName,
      principal: "apigateway.amazonaws.com",
      sourceArn: "${this.api.executionArn}/*/*"
    ) in handler;
  }

  pub inflight send(connectionId: str, message: str) {
    WebSocketApi.postToConnection(this.apiEndpoint, connectionId, message);
  }

  pub inflight url(): str {
    return this.wsEndpoint;
  }

  pub onLift(host: std.IInflightHost, ops: Array<str>) {
    if let host = aws.Function.from(host) {
      if ops.contains("send") {
        host.addPolicyStatements(aws.PolicyStatement {
          actions: ["execute-api:*"],
          resources: ["${this.api.executionArn}/*"],
          effect: aws.Effect.ALLOW,
        });
      }
    }
  }

  extern "./post-to-connection.js" static inflight postToConnection(endpoint: str, connectionId: str, data: str);
}
