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
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:scopeguard_app_client/src/protocol/scope_room/room_protocol.dart'
    as _ig6ucbzi;
import 'package:scopeguard_app_client/src/protocol/scope_room/room_state.dart'
    as _ig9hugfz;
import 'package:scopeguard_app_client/src/protocol/scopeguard/sg_session.dart'
    as _ihblnf3k;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// Scope Room — ScopeGuard's Track 1 ("Here, together") experience.
///
/// At a kickoff meeting the client, developers and anyone else in the room join one order from their own
/// phones (4-letter code or QR). Everyone sees the live quote; the client can switch optional items on or
/// off and every phone updates instantly. Each person taps "Agree". When everyone present agrees to the
/// same version, the scope is agreed in person: every phone lights up in a wave, the agreement (who, which
/// version, which fingerprint) is stored, and it is posted into the order's chat on the website.
/// If the quote changes afterwards (on any device or on the website), earlier agreements stop counting.
/// {@category Endpoint}
class EndpointScopeRoom extends _isc.EndpointRef {
  EndpointScopeRoom(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'scopeRoom';

  /// Server clock, so every phone fires the lock wave at the same real moment.
  _ida.Future<DateTime> now() => caller.callServerEndpoint<DateTime>(
    'scopeRoom',
    'now',
    {},
  );

  /// Open a room for an order you can see (the client who owns it, or a developer). If the order already
  /// has an open room you are added to that one instead.
  _ida.Future<_ig6ucbzi.RoomTicket> open(
    String sgToken,
    String orderId,
  ) => caller.callServerEndpoint<_ig6ucbzi.RoomTicket>(
    'scopeRoom',
    'open',
    {
      'sgToken': sgToken,
      'orderId': orderId,
    },
  );

  /// Join by code. Signed-in ScopeGuard users who can see the order join with their real role
  /// (client / dev); anyone else joins as a guest who can watch and agree.
  _ida.Future<_ig6ucbzi.RoomTicket> join(
    String code,
    String name,
    String sgToken,
  ) => caller.callServerEndpoint<_ig6ucbzi.RoomTicket>(
    'scopeRoom',
    'join',
    {
      'code': code,
      'name': name,
      'sgToken': sgToken,
    },
  );

  /// The client switches an optional item on or off. Every phone (and the website) sees the new total,
  /// and everyone has to agree again.
  _ida.Future<void> toggle(
    String code,
    String token,
    String moduleId,
    bool included,
  ) => caller.callServerEndpoint<void>(
    'scopeRoom',
    'toggle',
    {
      'code': code,
      'token': token,
      'moduleId': moduleId,
      'included': included,
    },
  );

  /// "I agree to this scope" (or take it back). Only counts for the current version of the quote.
  _ida.Future<void> agree(
    String code,
    String token,
    bool yes,
  ) => caller.callServerEndpoint<void>(
    'scopeRoom',
    'agree',
    {
      'code': code,
      'token': token,
      'yes': yes,
    },
  );

  /// Host: open the scope for changes again after an agreement (everyone must agree again).
  _ida.Future<void> reopen(
    String code,
    String token,
  ) => caller.callServerEndpoint<void>(
    'scopeRoom',
    'reopen',
    {
      'code': code,
      'token': token,
    },
  );

  /// Host: the meeting is over. The code stops working; the agreement stays on the order.
  _ida.Future<void> end(
    String code,
    String token,
  ) => caller.callServerEndpoint<void>(
    'scopeRoom',
    'end',
    {
      'code': code,
      'token': token,
    },
  );

  _ida.Future<void> leave(
    String code,
    String token,
  ) => caller.callServerEndpoint<void>(
    'scopeRoom',
    'leave',
    {
      'code': code,
      'token': token,
    },
  );

  /// Live room. Keeps the member "present" while open, and re-reads the order every few seconds so
  /// changes made on the website (e.g. the developer revising a price) show up here too.
  _ida.Stream<_ig9hugfz.RoomState> watch(
    String code,
    String token,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ig9hugfz.RoomState>,
        _ig9hugfz.RoomState
      >(
        'scopeRoom',
        'watch',
        {
          'code': code,
          'token': token,
        },
        {},
      );
}

/// Sign in with a ScopeGuard account. The token is the same JWT the website uses.
/// {@category Endpoint}
class EndpointAccount extends _isc.EndpointRef {
  EndpointAccount(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'account';

  _ida.Future<_ihblnf3k.SgSession> login(
    String email,
    String password,
  ) => caller.callServerEndpoint<_ihblnf3k.SgSession>(
    'account',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  _ida.Future<_ihblnf3k.SgSession> register(
    String name,
    String email,
    String password,
    String role,
  ) => caller.callServerEndpoint<_ihblnf3k.SgSession>(
    'account',
    'register',
    {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    },
  );

  /// Restores a saved session; throws 401 when the token expired.
  _ida.Future<_ihblnf3k.SgSession> me(String token) =>
      caller.callServerEndpoint<_ihblnf3k.SgSession>(
        'account',
        'me',
        {'token': token},
      );
}

/// The developer side ("the kitchen"): order queue, quote approval and revisions, accepting orders,
/// linking the GitHub repo and sending priced add-ons.
/// {@category Endpoint}
class EndpointKitchen extends _isc.EndpointRef {
  EndpointKitchen(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'kitchen';

  _ida.Future<String> queue(String token) => caller.callServerEndpoint<String>(
    'kitchen',
    'queue',
    {'token': token},
  );

  /// Approves the AI-drafted quote as-is and sends it to the client.
  _ida.Future<String> approveQuote(
    String token,
    String quoteId,
  ) => caller.callServerEndpoint<String>(
    'kitchen',
    'approveQuote',
    {
      'token': token,
      'quoteId': quoteId,
    },
  );

  _ida.Future<String> reprice(
    String token,
    String quoteId,
    String moduleId,
    int priceCents,
    String note,
  ) => caller.callServerEndpoint<String>(
    'kitchen',
    'reprice',
    {
      'token': token,
      'quoteId': quoteId,
      'moduleId': moduleId,
      'priceCents': priceCents,
      'note': note,
    },
  );

  _ida.Future<String> acceptOrder(
    String token,
    String orderId,
  ) => caller.callServerEndpoint<String>(
    'kitchen',
    'acceptOrder',
    {
      'token': token,
      'orderId': orderId,
    },
  );

  _ida.Future<String> connectRepo(
    String token,
    String orderId,
    String repoUrl,
  ) => caller.callServerEndpoint<String>(
    'kitchen',
    'connectRepo',
    {
      'token': token,
      'orderId': orderId,
      'repoUrl': repoUrl,
    },
  );

  _ida.Future<String> offerAddon(
    String token,
    String orderId,
    String title,
    String description,
    int priceCents,
  ) => caller.callServerEndpoint<String>(
    'kitchen',
    'offerAddon',
    {
      'token': token,
      'orderId': orderId,
      'title': title,
      'description': description,
      'priceCents': priceCents,
    },
  );
}

/// Shared by clients and developers: one order with its chat, live updates, and Proof-of-Delivery.
/// {@category Endpoint}
class EndpointOrders extends _isc.EndpointRef {
  EndpointOrders(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'orders';

  /// {order, messages, git?}
  _ida.Future<String> get(
    String token,
    String orderId,
  ) => caller.callServerEndpoint<String>(
    'orders',
    'get',
    {
      'token': token,
      'orderId': orderId,
    },
  );

  _ida.Future<String> send(
    String token,
    String orderId,
    String content,
  ) => caller.callServerEndpoint<String>(
    'orders',
    'send',
    {
      'token': token,
      'orderId': orderId,
      'content': content,
    },
  );

  _ida.Future<String> audit(
    String token,
    String orderId,
  ) => caller.callServerEndpoint<String>(
    'orders',
    'audit',
    {
      'token': token,
      'orderId': orderId,
    },
  );

  _ida.Future<String> proofScore(
    String token,
    String devId,
  ) => caller.callServerEndpoint<String>(
    'orders',
    'proofScore',
    {
      'token': token,
      'devId': devId,
    },
  );

  /// Live order: emits {order, messages} now and again whenever anything changes, including changes
  /// made on the website, by GitHub pushes, Stripe payments or the Proof auditor.
  _ida.Stream<String> watch(
    String token,
    String orderId,
  ) => caller.callStreamingServerEndpoint<_ida.Stream<String>, String>(
    'orders',
    'watch',
    {
      'token': token,
      'orderId': orderId,
    },
    {},
  );
}

/// The client side of ScopeGuard: the menu, ordering, AI scoping, the bill and payment.
/// Results are ScopeGuard's own JSON (the same shape the website renders).
/// {@category Endpoint}
class EndpointShop extends _isc.EndpointRef {
  EndpointShop(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'shop';

  _ida.Future<String> menu(String token) => caller.callServerEndpoint<String>(
    'shop',
    'menu',
    {'token': token},
  );

  _ida.Future<String> myOrders(String token) =>
      caller.callServerEndpoint<String>(
        'shop',
        'myOrders',
        {'token': token},
      );

  /// Menu-only cart: creates the order and returns {orderId, checkoutUrl}.
  _ida.Future<String> orderFromMenu(
    String token,
    String projectBrief,
    List<String> itemIds,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'orderFromMenu',
    {
      'token': token,
      'projectBrief': projectBrief,
      'itemIds': itemIds,
    },
  );

  /// Custom work (plus any menu items): returns {orderId, title, questions:[{question, suggestions}]}.
  _ida.Future<String> startScoping(
    String token,
    String projectBrief,
    String customRequest,
    List<String> menuItemIds,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'startScoping',
    {
      'token': token,
      'projectBrief': projectBrief,
      'customRequest': customRequest,
      'menuItemIds': menuItemIds,
    },
  );

  /// Answers to the AI's questions: returns {order} with the AI-drafted quote (a developer reviews it next).
  _ida.Future<String> answerScoping(
    String token,
    String orderId,
    List<String> answers,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'answerScoping',
    {
      'token': token,
      'orderId': orderId,
      'answers': answers,
    },
  );

  /// Switch an optional item on or off on the live bill.
  _ida.Future<String> toggle(
    String token,
    String orderId,
    String moduleId,
    bool included,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'toggle',
    {
      'token': token,
      'orderId': orderId,
      'moduleId': moduleId,
      'included': included,
    },
  );

  /// Returns {checkoutUrl, scopeHash}. The Stripe session id is part of the URL; pass it to [verifyPayment].
  _ida.Future<String> checkout(
    String token,
    String orderId,
    int quoteVersion,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'checkout',
    {
      'token': token,
      'orderId': orderId,
      'quoteVersion': quoteVersion,
    },
  );

  /// Confirms a Stripe payment server-side (works without webhooks).
  _ida.Future<String> verifyPayment(
    String token,
    String stripeSessionId,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'verifyPayment',
    {
      'token': token,
      'stripeSessionId': stripeSessionId,
    },
  );

  _ida.Future<String> payAddon(
    String token,
    String orderId,
    String addonId,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'payAddon',
    {
      'token': token,
      'orderId': orderId,
      'addonId': addonId,
    },
  );

  _ida.Future<String> skipAddon(
    String token,
    String orderId,
    String addonId,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'skipAddon',
    {
      'token': token,
      'orderId': orderId,
      'addonId': addonId,
    },
  );

  _ida.Future<String> acceptDelivery(
    String token,
    String orderId,
  ) => caller.callServerEndpoint<String>(
    'shop',
    'acceptDelivery',
    {
      'token': token,
      'orderId': orderId,
    },
  );
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    scopeRoom = EndpointScopeRoom(this);
    account = EndpointAccount(this);
    kitchen = EndpointKitchen(this);
    orders = EndpointOrders(this);
    shop = EndpointShop(this);
  }

  late final EndpointScopeRoom scopeRoom;

  late final EndpointAccount account;

  late final EndpointKitchen kitchen;

  late final EndpointOrders orders;

  late final EndpointShop shop;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'scopeRoom': scopeRoom,
    'account': account,
    'kitchen': kitchen,
    'orders': orders,
    'shop': shop,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {};
}
