/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;
import '../scope_room/scope_room_endpoint.dart' as _if1zjrso;
import '../scopeguard/account_endpoint.dart' as _i7h3j9t6;
import '../scopeguard/kitchen_endpoint.dart' as _ipq6augf;
import '../scopeguard/orders_endpoint.dart' as _ir0kndsg;
import '../scopeguard/shop_endpoint.dart' as _i2j1extp;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    initializeOwnEndpoints(server);
  }

  @override
  void initializeOwnEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'scopeRoom': _if1zjrso.ScopeRoomEndpoint()
        ..initialize(
          server,
          'scopeRoom',
          null,
        ),
      'account': _i7h3j9t6.AccountEndpoint()
        ..initialize(
          server,
          'account',
          null,
        ),
      'kitchen': _ipq6augf.KitchenEndpoint()
        ..initialize(
          server,
          'kitchen',
          null,
        ),
      'orders': _ir0kndsg.OrdersEndpoint()
        ..initialize(
          server,
          'orders',
          null,
        ),
      'shop': _i2j1extp.ShopEndpoint()
        ..initialize(
          server,
          'shop',
          null,
        ),
    };
    connectors['scopeRoom'] = _is.EndpointConnector(
      name: 'scopeRoom',
      endpoint: endpoints['scopeRoom']!,
      methodConnectors: {
        'now': _is.MethodConnector(
          name: 'now',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint)
                  .now(session),
        ),
        'open': _is.MethodConnector(
          name: 'open',
          params: {
            'sgToken': _is.ParameterDescription(
              name: 'sgToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint).open(
                    session,
                    params['sgToken'],
                    params['orderId'],
                  ),
        ),
        'join': _is.MethodConnector(
          name: 'join',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'sgToken': _is.ParameterDescription(
              name: 'sgToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint).join(
                    session,
                    params['code'],
                    params['name'],
                    params['sgToken'],
                  ),
        ),
        'toggle': _is.MethodConnector(
          name: 'toggle',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'moduleId': _is.ParameterDescription(
              name: 'moduleId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'included': _is.ParameterDescription(
              name: 'included',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint)
                  .toggle(
                    session,
                    params['code'],
                    params['token'],
                    params['moduleId'],
                    params['included'],
                  ),
        ),
        'agree': _is.MethodConnector(
          name: 'agree',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'yes': _is.ParameterDescription(
              name: 'yes',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint).agree(
                    session,
                    params['code'],
                    params['token'],
                    params['yes'],
                  ),
        ),
        'reopen': _is.MethodConnector(
          name: 'reopen',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint)
                  .reopen(
                    session,
                    params['code'],
                    params['token'],
                  ),
        ),
        'end': _is.MethodConnector(
          name: 'end',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint).end(
                    session,
                    params['code'],
                    params['token'],
                  ),
        ),
        'leave': _is.MethodConnector(
          name: 'leave',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint).leave(
                    session,
                    params['code'],
                    params['token'],
                  ),
        ),
        'watch': _is.MethodStreamConnector(
          name: 'watch',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['scopeRoom'] as _if1zjrso.ScopeRoomEndpoint).watch(
                    session,
                    params['code'],
                    params['token'],
                  ),
        ),
      },
    );
    connectors['account'] = _is.EndpointConnector(
      name: 'account',
      endpoint: endpoints['account']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['account'] as _i7h3j9t6.AccountEndpoint).login(
                    session,
                    params['email'],
                    params['password'],
                  ),
        ),
        'register': _is.MethodConnector(
          name: 'register',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['account'] as _i7h3j9t6.AccountEndpoint).register(
                    session,
                    params['name'],
                    params['email'],
                    params['password'],
                    params['role'],
                  ),
        ),
        'me': _is.MethodConnector(
          name: 'me',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['account'] as _i7h3j9t6.AccountEndpoint).me(
                session,
                params['token'],
              ),
        ),
      },
    );
    connectors['kitchen'] = _is.EndpointConnector(
      name: 'kitchen',
      endpoint: endpoints['kitchen']!,
      methodConnectors: {
        'queue': _is.MethodConnector(
          name: 'queue',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['kitchen'] as _ipq6augf.KitchenEndpoint).queue(
                    session,
                    params['token'],
                  ),
        ),
        'approveQuote': _is.MethodConnector(
          name: 'approveQuote',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'quoteId': _is.ParameterDescription(
              name: 'quoteId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['kitchen'] as _ipq6augf.KitchenEndpoint)
                  .approveQuote(
                    session,
                    params['token'],
                    params['quoteId'],
                  ),
        ),
        'reprice': _is.MethodConnector(
          name: 'reprice',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'quoteId': _is.ParameterDescription(
              name: 'quoteId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'moduleId': _is.ParameterDescription(
              name: 'moduleId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'priceCents': _is.ParameterDescription(
              name: 'priceCents',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['kitchen'] as _ipq6augf.KitchenEndpoint).reprice(
                    session,
                    params['token'],
                    params['quoteId'],
                    params['moduleId'],
                    params['priceCents'],
                    params['note'],
                  ),
        ),
        'acceptOrder': _is.MethodConnector(
          name: 'acceptOrder',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['kitchen'] as _ipq6augf.KitchenEndpoint)
                  .acceptOrder(
                    session,
                    params['token'],
                    params['orderId'],
                  ),
        ),
        'connectRepo': _is.MethodConnector(
          name: 'connectRepo',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'repoUrl': _is.ParameterDescription(
              name: 'repoUrl',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['kitchen'] as _ipq6augf.KitchenEndpoint)
                  .connectRepo(
                    session,
                    params['token'],
                    params['orderId'],
                    params['repoUrl'],
                  ),
        ),
        'offerAddon': _is.MethodConnector(
          name: 'offerAddon',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'description': _is.ParameterDescription(
              name: 'description',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'priceCents': _is.ParameterDescription(
              name: 'priceCents',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['kitchen'] as _ipq6augf.KitchenEndpoint)
                  .offerAddon(
                    session,
                    params['token'],
                    params['orderId'],
                    params['title'],
                    params['description'],
                    params['priceCents'],
                  ),
        ),
      },
    );
    connectors['orders'] = _is.EndpointConnector(
      name: 'orders',
      endpoint: endpoints['orders']!,
      methodConnectors: {
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['orders'] as _ir0kndsg.OrdersEndpoint).get(
                session,
                params['token'],
                params['orderId'],
              ),
        ),
        'send': _is.MethodConnector(
          name: 'send',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'content': _is.ParameterDescription(
              name: 'content',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['orders'] as _ir0kndsg.OrdersEndpoint).send(
                session,
                params['token'],
                params['orderId'],
                params['content'],
              ),
        ),
        'audit': _is.MethodConnector(
          name: 'audit',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['orders'] as _ir0kndsg.OrdersEndpoint).audit(
                    session,
                    params['token'],
                    params['orderId'],
                  ),
        ),
        'proofScore': _is.MethodConnector(
          name: 'proofScore',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'devId': _is.ParameterDescription(
              name: 'devId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['orders'] as _ir0kndsg.OrdersEndpoint).proofScore(
                    session,
                    params['token'],
                    params['devId'],
                  ),
        ),
        'watch': _is.MethodStreamConnector(
          name: 'watch',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['orders'] as _ir0kndsg.OrdersEndpoint).watch(
                session,
                params['token'],
                params['orderId'],
              ),
        ),
      },
    );
    connectors['shop'] = _is.EndpointConnector(
      name: 'shop',
      endpoint: endpoints['shop']!,
      methodConnectors: {
        'menu': _is.MethodConnector(
          name: 'menu',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['shop'] as _i2j1extp.ShopEndpoint).menu(
                session,
                params['token'],
              ),
        ),
        'myOrders': _is.MethodConnector(
          name: 'myOrders',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['shop'] as _i2j1extp.ShopEndpoint).myOrders(
                session,
                params['token'],
              ),
        ),
        'orderFromMenu': _is.MethodConnector(
          name: 'orderFromMenu',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'projectBrief': _is.ParameterDescription(
              name: 'projectBrief',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'itemIds': _is.ParameterDescription(
              name: 'itemIds',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'returnUrl': _is.ParameterDescription(
              name: 'returnUrl',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['shop'] as _i2j1extp.ShopEndpoint).orderFromMenu(
                    session,
                    params['token'],
                    params['projectBrief'],
                    params['itemIds'],
                    returnUrl: params['returnUrl'],
                  ),
        ),
        'startScoping': _is.MethodConnector(
          name: 'startScoping',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'projectBrief': _is.ParameterDescription(
              name: 'projectBrief',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'customRequest': _is.ParameterDescription(
              name: 'customRequest',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'menuItemIds': _is.ParameterDescription(
              name: 'menuItemIds',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['shop'] as _i2j1extp.ShopEndpoint).startScoping(
                    session,
                    params['token'],
                    params['projectBrief'],
                    params['customRequest'],
                    params['menuItemIds'],
                  ),
        ),
        'answerScoping': _is.MethodConnector(
          name: 'answerScoping',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'answers': _is.ParameterDescription(
              name: 'answers',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['shop'] as _i2j1extp.ShopEndpoint).answerScoping(
                    session,
                    params['token'],
                    params['orderId'],
                    params['answers'],
                  ),
        ),
        'toggle': _is.MethodConnector(
          name: 'toggle',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'moduleId': _is.ParameterDescription(
              name: 'moduleId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'included': _is.ParameterDescription(
              name: 'included',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['shop'] as _i2j1extp.ShopEndpoint).toggle(
                session,
                params['token'],
                params['orderId'],
                params['moduleId'],
                params['included'],
              ),
        ),
        'checkout': _is.MethodConnector(
          name: 'checkout',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'quoteVersion': _is.ParameterDescription(
              name: 'quoteVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'returnUrl': _is.ParameterDescription(
              name: 'returnUrl',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['shop'] as _i2j1extp.ShopEndpoint).checkout(
                session,
                params['token'],
                params['orderId'],
                params['quoteVersion'],
                returnUrl: params['returnUrl'],
              ),
        ),
        'verifyPayment': _is.MethodConnector(
          name: 'verifyPayment',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'stripeSessionId': _is.ParameterDescription(
              name: 'stripeSessionId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['shop'] as _i2j1extp.ShopEndpoint).verifyPayment(
                    session,
                    params['token'],
                    params['stripeSessionId'],
                  ),
        ),
        'payAddon': _is.MethodConnector(
          name: 'payAddon',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'addonId': _is.ParameterDescription(
              name: 'addonId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'returnUrl': _is.ParameterDescription(
              name: 'returnUrl',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['shop'] as _i2j1extp.ShopEndpoint).payAddon(
                session,
                params['token'],
                params['orderId'],
                params['addonId'],
                returnUrl: params['returnUrl'],
              ),
        ),
        'syncPayment': _is.MethodConnector(
          name: 'syncPayment',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['shop'] as _i2j1extp.ShopEndpoint).syncPayment(
                    session,
                    params['token'],
                    params['orderId'],
                  ),
        ),
        'skipAddon': _is.MethodConnector(
          name: 'skipAddon',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'addonId': _is.ParameterDescription(
              name: 'addonId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['shop'] as _i2j1extp.ShopEndpoint).skipAddon(
                    session,
                    params['token'],
                    params['orderId'],
                    params['addonId'],
                  ),
        ),
        'acceptDelivery': _is.MethodConnector(
          name: 'acceptDelivery',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'orderId': _is.ParameterDescription(
              name: 'orderId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['shop'] as _i2j1extp.ShopEndpoint).acceptDelivery(
                    session,
                    params['token'],
                    params['orderId'],
                  ),
        ),
      },
    );
  }
}
